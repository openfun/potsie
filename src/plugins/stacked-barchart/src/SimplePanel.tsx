import React, { useLayoutEffect } from 'react';
import { GrafanaTheme, PanelProps } from '@grafana/data';
import { SimpleOptions } from 'types';
import { css } from 'emotion';
import { useStyles, useTheme2 } from '@grafana/ui';
import * as d3 from 'd3';

interface Props extends PanelProps<SimpleOptions> { }

export const SimplePanel: React.FC<Props> = ({ options, data, width, height }) => {
  const styles = useStyles(getStyles);
  const theme = useTheme2();
  const graphRef = React.useRef(null);
  const graphWrapperRef = React.useRef(null);
  const time_group_count = data.series[0].fields;
  const graphGroupValues = [time_group_count[0].values.buffer[0]];
  const graphData = new Array();
  let graphGroupValue = time_group_count[0].values.buffer[0];
  let graphGroup = { "group": graphGroupValue };
  let maxGroupCount = 0;
  let groupCount = 0;
  for (let i = 0; i < time_group_count[0].values.buffer.length; i++) {
    let time = time_group_count[0].values.buffer[i];
    let group = time_group_count[1].values.buffer[i];
    let count = time_group_count[2].values.buffer[i];
    if (graphGroupValue != time) {
      graphGroupValue = time;
      graphGroupValues.push(graphGroupValue)
      graphData.push(graphGroup);
      graphGroup = { "group": time };
      if (maxGroupCount < groupCount) {
        maxGroupCount = groupCount;
      }
      groupCount = 0;
    }
    graphGroup[group] = count;
    groupCount += count;
  }
  graphData.push(graphGroup);
  if (maxGroupCount < groupCount) {
    maxGroupCount = groupCount;
  }

  useLayoutEffect(() => {
    const svg = d3.select(graphRef.current);
    svg.selectAll("*").remove();
    d3.select(graphWrapperRef.current).selectAll("*").remove();

    svg
      .attr("width", width - 10)
      .attr("height", height -10)
      .attr("viewBox", `-50 10 ${width + 80} ${height}`)
      .append("g")

    const groups = graphGroupValues;
    const subgroups = Object.keys(graphData[0]).filter((x) => x != "group");
    console.log("groups", groups);
    console.log("subgroups", subgroups);

    // Add X axis
    const x = d3.scaleBand()
      .domain(groups)
      .range([0, width])
      .padding(0.2)
    svg.append("g")
      .attr("transform", `translate(0, ${height})`)
      .call(d3.axisBottom(x).tickSizeOuter(0));

    // Add Y axis
    const y = d3.scaleLinear()
      .domain([0, maxGroupCount])
      .range([height, 0]);
    svg.append("g")
      .call(d3.axisLeft(y));

    // color palette = one color per subgroup
    const color = d3.scaleOrdinal()
      .domain(subgroups)
      .range(theme.visualization.palette.slice(14))

    //stack the data? --> stack per subgroup
    const stackedData = d3.stack()
      .keys(subgroups)
      (graphData)

    console.log("stackedData", stackedData);

    // ----------------
    // Create a tooltip
    // ----------------
    const tooltip = d3.select(graphWrapperRef.current)
      .append("div")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background-color", "white")
      .style("color", "#000")
      .style("border-radius", "5px")
      .style("padding", "10px")

    // Three function that change the tooltip when user hover / move / leave a cell
    const mouseover = function (event) {
      const subgroupName = d3.select(this.parentNode).datum().key;
      const subgroupValue = event.data[subgroupName];
      tooltip
        .html(subgroupName + ":" + subgroupValue)
        .style("opacity", 1);
      
        svg.selectAll(".myRect").style("opacity", 0.2)
        // Highlight all rects of this subgroup with opacity 0.8. It is possible to select them since they have a specific class = their name.
        svg.selectAll("."+subgroupName)
          .style("opacity", 1)
    }
    const mousemove = function (event) {
      tooltip.style("transform", "translateY(-55%)")
        .style("left", (event.x) / 2 + "px")
        .style("top", (event.y) / 2 - 30 + "px")
    }
    const mouseleave = function (event) {
      tooltip
        .style("opacity", 0)
      svg.selectAll(".myRect")
        .style("opacity",1)
    }

    // Show the bars
    svg.append("g")
      .selectAll("g")
      // Enter in the stack data = loop key per key = group per group
      .data(stackedData)
      .join("g")
      .attr("fill", d => color(d.key))
      .attr("class", d => "myRect " + d.key ) // Add a class to each subgroup: their name
      .selectAll("rect")
      // enter a second time = loop subgroup per subgroup to add all rectangles
      .data(d => d)
      .join("rect")
      .attr("x", d => x(d.data.group))
      .attr("y", d => y(d[1]))
      .attr("height", d => y(d[0]) - y(d[1]))
      .attr("width", x.bandwidth())
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave)
  })

  return (
    <div className={styles}>
      <div ref={graphWrapperRef}></div>
      <svg ref={graphRef}></svg>

      {/* <div className={styles.textBox}>
        {options.showSeriesCount && (
          <div
            className={css`
              font-size: ${theme.typography.size[options.seriesCountSize]};
            `}
          >
            Number of series: {data.series.length}
          </div>
        )}
        <div>Text option value: {options.text}</div>
      </div> */}
    </div>
  );
};

const getStyles = (theme: GrafanaTheme) => css`
  padding: ${theme.spacing.sm};
`;
