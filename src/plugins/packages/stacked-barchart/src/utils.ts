import { DataFrame, FieldOverrideContext } from '@grafana/data';
import * as d3 from 'd3';

import { BarDatum, PreparedGraphFields, StackedBarchartOptions } from './types';

export const prepareGraphableFields = (
  series: DataFrame[] | undefined,
  options: StackedBarchartOptions
): PreparedGraphFields => {
  const result: PreparedGraphFields = {
    stacks: [],
    xDistinctGroups: [],
    yDistinctGroups: [],
    xMaxGroupCount: 0,
    error: '',
  };
  if (!series?.length) {
    result.error = 'No data';
    return result;
  }
  if (series[0].fields.length !== 3) {
    result.error = 'Data should have 3 columns';
    return result;
  }
  const xGroup = series[0].fields[options.xAxisColumn].values.toArray();
  const yGroup = series[0].fields[options.yAxisColumnGroup].values.toArray();
  const yCount = series[0].fields[options.yAxisColumn].values.toArray();
  let xGroupCount = 0;
  const xGroupByYgroup = xGroup.reduce((storage, item, index) => {
    const last = storage[storage.length - 1];
    if (last?.group === item) {
      last[yGroup[index]] = yCount[index];
      xGroupCount += yCount[index];
    } else {
      storage.push({ group: item, [yGroup[index]]: yCount[index] });
      result.xDistinctGroups.push(item);
      if (result.xMaxGroupCount < xGroupCount) {
        result.xMaxGroupCount = xGroupCount;
      }
      xGroupCount = yCount[index];
    }
    return storage;
  }, []);
  if (result.xMaxGroupCount < xGroupCount) {
    result.xMaxGroupCount = xGroupCount;
  }
  result.yDistinctGroups = Object.keys(xGroupByYgroup[0]).filter((x) => x !== 'group');
  result.stacks = d3.stack<BarDatum>().keys(result.yDistinctGroups)(xGroupByYgroup);
  return result;
};

export const countDigits = (value: number) => {
  if (value === 0) {
    return 1;
  }
  return 1 + Math.floor(Math.log(Math.abs(value)) / Math.log(10));
};

export const getColumnNamesOptions = async (context: FieldOverrideContext) => {
  const options = [];
  if (context.data[0] && context.data[0].fields) {
    for (let i = 0; i < context.data[0].fields.length; i++) {
      options.push({ value: i, label: context.data[0].fields[i].name });
    }
  }
  return Promise.resolve(options);
};
