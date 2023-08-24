// General utils

{
  metrics: {
    count: { id: '1', type: 'count' },
    cardinality(field):: {
      id: '1',
      type: 'cardinality',
      field: field,
    },
    max(field):: {
      id: '1',
      type: 'max',
      field: field,
    },
  },
  aggregations: {
    date_histogram(interval='1d', min_doc_count='1'):: {
      id: 'date',
      field: '@timestamp',
      type: 'date_histogram',
      settings: {
        interval: interval,
        min_doc_count: min_doc_count,
        trimEdges: '0',
      },
    },
  },
  functions: {
    double_escape_string(x):: std.strReplace(std.strReplace(std.strReplace(x, ':', '\\\\:'), '/', '\\\\/'), '-', '\\\\-'),
    single_escape_string(x):: std.strReplace(std.strReplace(std.strReplace(x, ':', '\\:'), '/', '\\/'), '-', '\\-'),
  },
}
