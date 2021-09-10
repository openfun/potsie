import React, { useLayoutEffect, useMemo, useRef } from 'react';
import ReactDOM from 'react-dom';
import useMeasure from 'react-use-measure';
import { PanelProps, classicColors } from '@grafana/data';
import { useTheme2 } from '@grafana/ui';
import { css } from '@emotion/css';
import * as d3 from 'd3';

import { BarDatum, StackedBarchartOptions } from './types';
import { prepareGraphableFields, countDigits } from './utils';

export const StackedBarchartPanel: React.FC<PanelProps<StackedBarchartOptions>> = ({
  options,
  data,
  width,
  height,
}) => {
  const theme = useTheme2();
  const graphRef = useRef(null);
  const graphTooltipRef = useRef(null);
  const [legendRef, legendMeasure] = useMeasure();
  const legendHeight = options.showLegend ? legendMeasure.height : 0;
  const svgHeight = height - legendHeight;

  const { stacks, xDistinctGroups, yDistinctGroups, xMaxGroupCount, error } = useMemo(
    () => prepareGraphableFields(data?.series, options),
    [data, options]
  );

  const colorScale = d3.scaleOrdinal().domain(yDistinctGroups).range(classicColors);

  useLayoutEffect(() => {
    if (error || !graphTooltipRef.current || !graphRef.current) {
      return;
    }
    const margin = {
      top: 5,
      right: 5,
      bottom: 40,
      left: 20 + 12 * countDigits(xMaxGroupCount),
    };
    const tooltip = d3.select(graphTooltipRef.current).style('display', 'none');
    const svg = d3.select(graphRef.current);
    svg.selectAll('*').remove();

    // X axis
    const xAxis = d3
      .scaleBand()
      .domain(xDistinctGroups)
      .range([0, width - margin.right - margin.left])
      .padding(0.2);

    const xAxisGenerator = d3.axisBottom(xAxis);

    if (options.isXContinuous) {
      let maxBinsModulo = Math.ceil(xDistinctGroups.length / options.numberOfBins);
      xAxisGenerator.tickValues(xDistinctGroups.filter((_, index) => index % maxBinsModulo === 0));
    }

    svg
      .append('g')
      .attr('transform', `translate(${margin.left}, ${svgHeight - margin.bottom})`)
      .call(xAxisGenerator)
      .selectAll('text')
      .style('fill', theme.colors.text.primary);

    svg
      .append('text')
      .attr('transform', `translate(${(width - margin.right + margin.left) / 2}, ${svgHeight - 8})`)
      .style('fill', theme.colors.text.primary)
      .style('text-anchor', 'middle')
      .text(options.xLabel);

    // Y axis
    const yAxis = d3
      .scaleLinear()
      .domain([0, xMaxGroupCount])
      .range([svgHeight - margin.bottom - margin.top, 0]);

    svg
      .append('g')
      .attr('transform', `translate(${margin.left}, ${margin.top})`)
      .call(d3.axisLeft(yAxis))
      .selectAll('text')
      .style('fill', theme.colors.text.primary);

    svg
      .append('text')
      .attr('transform', 'rotate(-90)')
      .attr('x', -(svgHeight - margin.bottom + margin.top) / 2)
      .attr('y', 15)
      .style('text-anchor', 'middle')
      .style('fill', theme.colors.text.primary)
      .text(options.yLabel);

    // Event listeners
    const mouseover = function (this: d3.BaseType | SVGElement, event: any) {
      const groupName = (d3.select(this as SVGElement).datum() as { data: BarDatum }).data.group;
      const subgroupName = (d3.select((this as SVGElement).parentNode as Element).datum() as { key: string }).key;
      ReactDOM.render(
        <>
          <div
            className={css`
              text-align: center;
              font-weight: 500;
              font-sixe: 150%;
            `}
          >
            {groupName}
          </div>
          {yDistinctGroups.map((item) => {
            return (
              <div
                key={item}
                className={css`
                  display: flex;
                  justify-content: space-between;
                  color: ${subgroupName === item ? theme.colors.text.maxContrast : theme.colors.text.primary};
                `}
              >
                <div>
                  <div
                    className={css`
                      background-color: ${colorScale(item) as string};
                      border-radius: 1px;
                      display: inline-block;
                      height: 4px;
                      margin-right: 8px;
                      width: 14px;
                    `}
                  />
                  <div
                    className={css`
                      font-size: 12px;
                      display: inline-block;
                      font-weight: ${subgroupName === item ? 500 : 200};
                    `}
                  >
                    {item}:
                  </div>
                </div>
                <div
                  className={css`
                    float: right;
                    padding-left: 15px;
                    font-weight: 500;
                  `}
                >
                  {event.data[item]}
                </div>
              </div>
            );
          })}
        </>,
        graphTooltipRef.current
      );
      tooltip.style('display', 'block');
      svg.selectAll('.myRect').style('opacity', 0.2);
      svg.selectAll('.' + subgroupName).style('opacity', 1);
    };

    const mousemove = function (this: d3.BaseType | SVGGElement) {
      const xPosition = d3.mouse(this as SVGGElement)[0];
      const yPosition = d3.mouse(this as SVGGElement)[1];
      const tooltipNode = tooltip.node() as HTMLDivElement | null;
      const dimensions = (tooltipNode as HTMLDivElement).getBoundingClientRect() as DOMRect;
      const defaultOffset = 10;
      const leftOffset = xPosition < width / 2 ? defaultOffset : -defaultOffset - dimensions.width;
      const topOffset = yPosition < height / 2 ? defaultOffset : -defaultOffset - dimensions.height;
      tooltip
        .style('left', `${margin.left + xPosition + leftOffset}px`)
        .style('top', `${margin.top + yPosition + topOffset}px`);
    };

    const mouseleave = function () {
      tooltip.style('display', 'none');
      svg.selectAll('.myRect').style('opacity', 1);
    };

    // Bars
    svg
      .append('g')
      .attr('transform', `translate(${margin.left}, ${margin.top})`)
      .selectAll('g')
      // Enter in the stack data = loop key per key = group per group
      .data<d3.Series<BarDatum, string>>(stacks)
      .join('g')
      .attr('fill', (d) => colorScale(d.key) as string)
      .attr('class', (d) => 'myRect ' + d.key) // Add a class to each subgroup: their name
      .selectAll('rect')
      // enter a second time = loop subgroup per subgroup to add all rectangles
      .data<d3.SeriesPoint<BarDatum>>((d) => d)
      .join('rect')
      .attr('x', (d) => xAxis(d.data.group) as number)
      .attr('y', (d) => yAxis(d[1]) as number)
      .attr('height', (d) => (yAxis(d[0]) as number) - (yAxis(d[1]) as number))
      .attr('width', xAxis.bandwidth())
      .on('mouseover', mouseover)
      .on('mousemove', mousemove)
      .on('mouseleave', mouseleave);
  }, [
    colorScale,
    error,
    height,
    legendHeight,
    options,
    stacks,
    svgHeight,
    theme,
    width,
    xDistinctGroups,
    xMaxGroupCount,
    yDistinctGroups,
  ]);

  if (error) {
    return (
      <div className="panel-empty" role="figure">
        <p>{error}</p>
      </div>
    );
  }

  return (
    <div role="figure">
      <div
        className={css`
          position: relative;
        `}
      >
        <div
          ref={graphTooltipRef}
          className={css`
            background-color: ${theme.colors.background.primary};
            border-radius: 5px;
            color: ${theme.colors.text.primary};
            font-size: 12px;
            padding: 10px;
            position: absolute;
            white-space: nowrap;
            pointer-events: none;
          `}
        />
      </div>
      <svg ref={graphRef} width={width} height={svgHeight} />
      <div
        ref={legendRef}
        style={{ display: options.showLegend ? 'flex' : 'none' }}
        className={css`
          flex-wrap: wrap;
          margin-top: -5px;
          overflow: hidden;
          width: 100%;
        `}
      >
        {yDistinctGroups.map((item) => {
          return (
            <div
              key={item}
              className={css`
                align-items: center;
                display: flex;
                padding-left: 10px;
                justify-content: space-around;
              `}
            >
              <div
                className={css`
                  background-color: ${colorScale(item) as string};
                  border-radius: 1px;
                  display: inline-block;
                  height: 4px;
                  margin-right: 8px;
                  width: 14px;
                `}
              />
              <div
                className={css`
                  font-size: 12px;
                `}
              >
                {item}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
