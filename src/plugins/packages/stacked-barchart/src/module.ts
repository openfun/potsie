import { PanelPlugin } from '@grafana/data';

import { StackedBarchartPanel } from './StackedBarchartPanel';
import { StackedBarchartOptions } from './types';
import { getColumnNamesOptions } from './utils';

export const plugin = new PanelPlugin<StackedBarchartOptions>(StackedBarchartPanel).setPanelOptions((builder) => {
  return builder
    .addTextInput({
      path: 'xLabel',
      name: 'Label for the x Axis',
      defaultValue: '',
    })
    .addTextInput({
      path: 'yLabel',
      name: 'Label for the y Axis',
      defaultValue: '',
    })
    .addBooleanSwitch({
      path: 'isXContinuous',
      name: 'Are values on the x Axis continuous?',
      description: 'When the values on the x Axis are continuous we can limit the number of x Axis labels',
      defaultValue: false,
    })
    .addNumberInput({
      path: 'numberOfBins',
      name: 'Number of bins',
      defaultValue: 10,
      settings: {
        min: 1,
        integer: true,
      },
      showIf: (config) => config.isXContinuous,
    })
    .addBooleanSwitch({
      path: 'showLegend',
      name: 'Show the legend?',
      defaultValue: true,
    })
    .addSelect({
      path: 'xAxisColumn',
      name: 'Which column should be used for the x Axis?',
      defaultValue: 0,
      settings: {
        options: [],
        getOptions: getColumnNamesOptions,
      },
    })
    .addSelect({
      path: 'yAxisColumnGroup',
      name: 'Which column should be used to group values on the y Axis?',
      defaultValue: 1,
      settings: {
        options: [],
        getOptions: getColumnNamesOptions,
      },
    })
    .addSelect({
      path: 'yAxisColumn',
      name: 'Which column should be used for the y Axis?',
      defaultValue: 2,
      settings: {
        options: [],
        getOptions: getColumnNamesOptions,
      },
    });
});
