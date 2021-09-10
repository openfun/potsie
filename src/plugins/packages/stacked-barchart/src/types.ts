export interface BarDatum {
  group: string;
}

export interface PreparedGraphFields {
  stacks: Array<d3.Series<BarDatum, string>>;
  xDistinctGroups: string[];
  yDistinctGroups: string[];
  xMaxGroupCount: number;
  error: string;
}

export interface StackedBarchartOptions {
  xLabel: string;
  yLabel: string;
  isXContinuous: boolean;
  numberOfBins: number;
  showLegend: boolean;
  xAxisColumn: number;
  yAxisColumn: number;
  yAxisColumnGroup: number;
}
