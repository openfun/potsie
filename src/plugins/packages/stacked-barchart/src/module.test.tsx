import React from 'react';
import { render, screen } from '@testing-library/react';
import './jest.mock'; // Must be imported before StackedBarchartPanel
import { dateTime, LoadingState, PanelData, toDataFrame } from '@grafana/data';
import userEvent from '@testing-library/user-event';
import * as d3 from 'd3';

import { BarDatum, StackedBarchartOptions } from './types';
import { countDigits, prepareGraphableFields, getColumnNamesOptions } from './utils';
import { StackedBarchartPanel } from './StackedBarchartPanel';

const getDefaultOptions = (): StackedBarchartOptions => {
  return {
    xLabel: 'x label',
    yLabel: 'y label',
    isXContinuous: false,
    numberOfBins: 0,
    showLegend: true,
    xAxisColumn: 0,
    yAxisColumnGroup: 1,
    yAxisColumn: 2,
  };
};

const getDefaultPanelData = (): PanelData => {
  return {
    state: LoadingState.Done,
    series: [],
    timeRange: { from: dateTime(), to: dateTime(), raw: { from: dateTime(), to: dateTime() } },
  };
};

const getDefaultStackedBarchartProps = () => {
  return {
    options: getDefaultOptions(),
    data: getDefaultPanelData(),
    width: 400,
    height: 400,
    id: 0,
    timeRange: getDefaultPanelData().timeRange,
    timeZone: 'utc',
    transparent: false,
    fieldConfig: {
      defaults: {},
      overrides: [],
    },
    renderCounter: 0,
    title: '',
    eventBus: {} as any,
    onFieldConfigChange: () => {},
    onOptionsChange: () => {},
    onChangeTimeRange: () => {},
    replaceVariables: (s: any) => s,
  };
};

test.each([
  { arg: 0, expected: 1 },
  { arg: 1, expected: 1 },
  { arg: -10, expected: 2 },
  { arg: 10, expected: 2 },
  { arg: 99, expected: 2 },
  { arg: 100, expected: 3 },
  { arg: 999, expected: 3 },
  { arg: 2021, expected: 4 },
  { arg: -2021, expected: 4 },
])('countDigits with a valid argument should return the expected value', ({ arg, expected }) => {
  expect(countDigits(arg)).toBe(expected);
});

test.each([{ series: undefined }, { series: [] }])(
  'prepareGraphableFields with no fields data should return an error',
  ({ series }) => {
    const result = prepareGraphableFields(series, getDefaultOptions());
    expect(result.error).toEqual('No data');
  }
);

test.each([
  { fields: null },
  { fields: undefined },
  { fields: 0 },
  { fields: [] },
  { fields: [1] },
  { fields: [1, 2] },
  { fields: [1, 2, 3, 4] },
])('prepareGraphableFields with invalid fields data should return an error', ({ fields }) => {
  const series = [toDataFrame({ fields })];
  const result = prepareGraphableFields(series, getDefaultOptions());
  expect(result.error).toEqual('Data should have 3 columns');
});

test('prepareGraphableFields with valid fields in decreasing order should return the expected value', () => {
  const series = [
    toDataFrame({
      fields: [
        { values: ['foo', 'foo', 'foo', 'bar', 'bar', 'baz', 'baz', 'baz', 'baz'] },
        { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
        { values: [8, 7, 6, 5, 4, 3, 2, 1, 0] },
      ],
    }),
  ];
  const result = prepareGraphableFields(series, getDefaultOptions());
  const yDistinctGroups = ['toto', 'tata', 'titi'];
  const xGroupByYgroup = [
    { group: 'foo', toto: 8, tata: 7, titi: 6 },
    { group: 'bar', toto: 5, tata: 4 },
    { group: 'baz', toto: 3, tata: 2, titi: 1, tutu: 0 },
  ];
  expect(result).toEqual({
    error: '',
    stacks: d3.stack<BarDatum>().keys(yDistinctGroups)(xGroupByYgroup),
    xDistinctGroups: ['foo', 'bar', 'baz'],
    xMaxGroupCount: 21,
    yDistinctGroups,
  });
});

test('prepareGraphableFields with valid fields in increasing order should return the expected value', () => {
  const series = [
    toDataFrame({
      fields: [
        { values: ['foo', 'foo', 'foo', 'bar', 'bar', 'baz', 'baz', 'baz', 'baz'] },
        { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
        { values: [0, 1, 2, 3, 4, 5, 6, 7, 8] },
      ],
    }),
  ];
  const result = prepareGraphableFields(series, getDefaultOptions());
  const yDistinctGroups = ['toto', 'tata', 'titi'];
  const xGroupByYgroup = [
    { group: 'foo', toto: 0, tata: 1, titi: 2 },
    { group: 'bar', toto: 3, tata: 4 },
    { group: 'baz', toto: 5, tata: 6, titi: 7, tutu: 8 },
  ];
  expect(result).toEqual({
    error: '',
    stacks: d3.stack<BarDatum>().keys(yDistinctGroups)(xGroupByYgroup),
    xDistinctGroups: ['foo', 'bar', 'baz'],
    xMaxGroupCount: 26,
    yDistinctGroups,
  });
});

test.each([
  { data: [], expected: [] },
  { data: [toDataFrame({ fields: null })], expected: [] },
  { data: [toDataFrame({ fields: undefined })], expected: [] },
  { data: [toDataFrame({ fields: 0 })], expected: [] },
  { data: [toDataFrame({ fields: [] })], expected: [] },
  { data: [toDataFrame({ fields: [{ name: 'foo' }] })], expected: [{ value: 0, label: 'foo' }] },
  {
    data: [toDataFrame({ fields: [{ name: 'foo' }, { name: 'bar' }] })],
    expected: [
      { value: 0, label: 'foo' },
      { value: 1, label: 'bar' },
    ],
  },
])(
  'getColumnNamesOptions with valid and invalid data should return the expected options',
  async ({ data, expected }) => {
    const options = await getColumnNamesOptions({ data });
    expect(options).toEqual(expected);
  }
);

describe('render the HTML of the stacked barchart', () => {
  test('StackedBarchartPanel with no data should show no data', () => {
    render(<StackedBarchartPanel {...getDefaultStackedBarchartProps()} />);
    expect(screen.getByRole('figure').textContent).toBe('No data');
  });

  test.each([
    { fields: null },
    { fields: undefined },
    { fields: 0 },
    { fields: [] },
    { fields: [1] },
    { fields: [1, 2] },
    { fields: [1, 2, 3, 4] },
  ])('StackedBarchartPanel with invalid data should show an error message', ({ fields }) => {
    const props = getDefaultStackedBarchartProps();
    props.data.series = [toDataFrame({ fields })];
    render(<StackedBarchartPanel {...props} />);
    expect(screen.getByRole('figure').textContent).toBe('Data should have 3 columns');
  });

  test('StackedBarchartPanel with valid data should show a stacked barchart', () => {
    const props = getDefaultStackedBarchartProps();
    const fields = [
      { values: ['foo', 'foo', 'foo', 'bar', 'bar', 'baz', 'baz', 'baz', 'baz'] },
      { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
      { values: [8, 7, 6, 5, 4, 3, 2, 1, 0] },
    ];
    props.data.series = [toDataFrame({ fields })];
    render(<StackedBarchartPanel {...props} />);
    const container = screen.getByRole('figure');
    expect(container.childElementCount).toBe(3);
    const svg = container.getElementsByTagName('svg')[0];
    expect(svg.childElementCount).toBe(5);
    const xAxis = svg.children[0];
    const xAxisText = svg.children[1];
    const yAxis = svg.children[2];
    const yAxisText = svg.children[3];
    const bars = svg.children[4];
    expect(xAxis.getElementsByTagName('g').length).toBe(3); // foo, bar, baz
    expect(xAxisText.textContent).toBe('x label');
    expect(yAxis.getElementsByTagName('g').length).toBe(d3.scaleLinear().domain([0, 21]).ticks().length);
    expect(yAxisText.textContent).toBe('y label');
    expect(bars.children.length).toBe(3); // toto, tata, titi
  });

  test.each([
    { numberOfBins: 0, expected: 1 },
    { numberOfBins: 1, expected: 1 },
    { numberOfBins: 2, expected: 2 },
    { numberOfBins: 3, expected: 3 },
    { numberOfBins: 4, expected: 3 },
  ])('xAxis labels should be of expected length when isXContinuous is true', ({ numberOfBins, expected }) => {
    const props = getDefaultStackedBarchartProps();
    const fields = [
      { values: [1, 1, 1, 2, 2, 3, 3, 3, 3] },
      { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
      { values: [8, 7, 6, 5, 4, 3, 2, 1, 0] },
    ];
    props.data.series = [toDataFrame({ fields })];
    const options = getDefaultOptions();
    options.isXContinuous = true;
    options.numberOfBins = numberOfBins;
    props.options = options;
    render(<StackedBarchartPanel {...props} />);
    const xAxis = screen.getByRole('figure').getElementsByTagName('svg')[0].children[0];
    expect(xAxis.getElementsByTagName('g').length).toBe(expected);
  });

  test('mouseover/mouseleave events should show/hide the tooltip', () => {
    const props = getDefaultStackedBarchartProps();
    const fields = [
      { values: ['foo', 'foo', 'foo', 'bar', 'bar', 'baz', 'baz', 'baz', 'baz'] },
      { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
      { values: [8, 7, 6, 5, 4, 3, 2, 1, 0] },
    ];
    props.data.series = [toDataFrame({ fields })];
    render(<StackedBarchartPanel {...props} />);
    const container = screen.getByRole('figure');
    const bars = container.getElementsByTagName('svg')[0].children[4];
    const bar = bars.firstElementChild?.firstElementChild as Element;
    const tooltip = container.firstElementChild?.firstElementChild as HTMLDivElement;
    userEvent.hover(bar);
    expect(tooltip.style.display).toBe('block');
    userEvent.unhover(bar);
    expect(tooltip.style.display).toBe('none');
  });

  test('mousemove event should make the tooltip follow the mouse', () => {
    const props = getDefaultStackedBarchartProps();
    const fields = [
      { values: ['foo', 'foo', 'foo', 'bar', 'bar', 'baz', 'baz', 'baz', 'baz'] },
      { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
      { values: [8, 7, 6, 5, 4, 3, 2, 1, 0] },
    ];
    props.data.series = [toDataFrame({ fields })];
    render(<StackedBarchartPanel {...props} />);
    const container = screen.getByRole('figure');
    const bars = container.getElementsByTagName('svg')[0].children[4];
    const bar = bars.firstElementChild?.firstElementChild;
    const tooltip = container.firstElementChild?.firstElementChild as HTMLDivElement;
    bar?.dispatchEvent(new MouseEvent('mousemove', { bubbles: true, clientX: 390, clientY: 390 }));
    expect(tooltip.style.top).toBe('385px');
    expect(tooltip.style.left).toBe('424px');
    bar?.dispatchEvent(new MouseEvent('mousemove', { bubbles: true, clientX: 0, clientY: 0 }));
    expect(tooltip.style.top).toBe('15px');
    expect(tooltip.style.left).toBe('54px');
  });

  test('showLegend option should hide the legened when set to false', () => {
    const props = getDefaultStackedBarchartProps();
    const options = getDefaultOptions();
    options.showLegend = false;
    props.options = options;
    const fields = [
      { values: ['foo', 'foo', 'foo', 'bar', 'bar', 'baz', 'baz', 'baz', 'baz'] },
      { values: ['toto', 'tata', 'titi', 'toto', 'tata', 'toto', 'tata', 'titi', 'tutu'] },
      { values: [8, 7, 6, 5, 4, 3, 2, 1, 0] },
    ];
    props.data.series = [toDataFrame({ fields })];
    render(<StackedBarchartPanel {...props} />);
    expect((screen.getByRole('figure').lastElementChild as HTMLDivElement).style.display).toBe('none');
  });
});
