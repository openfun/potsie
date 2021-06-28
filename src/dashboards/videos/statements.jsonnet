local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

local common = import 'common.libsonnet';

dashboard.new(
  'Statements',
  tags=['xAPI', 'video', 'staff'],
  editable=false
)
.addTemplate(common.templates.school)
.addTemplate(common.templates.course)
.addTemplate(common.templates.session)
.addTemplate(common.templates.statements_interval)
.addPanel(
  statPanel.new(
    title='Statements',
    description=|||
      Total count of statements in the selected time range.
    |||,
    datasource=common.constants.lrs,
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query=common.queries.school_course_session,
      metrics=[common.objects.count_metric],
      bucketAggs=[common.objects.date_histogram('$STATEMENTS_INTERVAL')],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 0, y: 0, w: 6, h: 6 }
)
.addPanel(
  statPanel.new(
    title='Videos',
    description=|||
      Total number of videos which had at least one interaction in the selected time range.
    |||,
    datasource=common.constants.lrs,
    reducerFunction='count',
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query=common.queries.school_course_session,
      metrics=[common.objects.count_metric],
      bucketAggs=[
        {
          id: 'video',
          field: common.fields.video_id,
          type: 'terms',
          settings: {
            min_doc_count: '1',
            size: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 6, y: 0, w: 6, h: 6 }
)
.addPanel(
  graphPanel.new(
    title='Statements by ${STATEMENTS_INTERVAL}',
    description=|||
      Number of statements by ${STATEMENTS_INTERVAL}.
      The interval is controlled by the `Statements interval` variable
    |||,
    datasource=common.constants.lrs,
    bars=true,
    lines=false,
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query=common.queries.school_course_session,
      metrics=[common.objects.count_metric],
      bucketAggs=[common.objects.date_histogram('$STATEMENTS_INTERVAL')],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 12, y: 0, w: 12, h: 6 }
)
.addPanel(
  {
    title: 'Video length',
    description: |||
      The distribution of the video durations in seconds.
      On the Y-axis is the video count and on the X-axis the duration.
    |||,
    datasource: common.constants.lrs,
    fieldConfig: {
      defaults: {
        color: {
          mode: 'palette-classic',
        },
        displayName: 'Video count',
        unit: 'none',
      },
    },
    id: 6,
    options: {
      bucketOffset: 0,
      combine: false,
      legend: {
        displayMode: 'list',
        placement: 'bottom',
      },
    },
    targets: [
      {
        bucketAggs: [
          {
            field: common.fields.video_id,
            id: '3',
            settings: {
              min_doc_count: '0',
              order: 'desc',
              orderBy: '1',
              size: '0',
            },
            type: 'terms',
          },
        ],
        metrics: [
          {
            field: common.fields.result_extensions_length,
            id: '1',
            type: 'max',
          },
        ],
        query: common.queries.school_course_session,
        refId: 'A',
        timeField: 'timestamp',
      },
    ],
    timeFrom: null,
    timeShift: null,
    type: 'histogram',
  },
  gridPos={ x: 0, y: 6, w: 6, h: 9 }
)
.addPanel(
  {
    title: 'Completion threshold by video',
    description: |||
      The distribution of the completion threshold by video.
      On the Y-axis is the number of videos and on the X-axis the threshold interval.
    |||,
    datasource: common.constants.lrs,
    fieldConfig: {
      defaults: {
        color: {
          mode: 'palette-classic',
        },
        displayName: 'Video count',
        unit: 'none',
      },
    },
    id: 10,
    options: {
      bucketOffset: 0,
      combine: false,
      legend: {
        displayMode: 'list',
        placement: 'bottom',
      },
    },
    targets: [
      {
        bucketAggs: [
          {
            field: 'object.id.keyword',
            id: '4',
            settings: {
              min_doc_count: '1',
              order: 'desc',
              orderBy: '1',
              size: '0',
            },
            type: 'terms',
          },
        ],
        metrics: [
          {
            field: common.fields.context_extensions_completion_threshold,
            id: '1',
            type: 'max',
          },
        ],
        query: '%(course_query)s AND verb.id:"%(completed)s"' % {
          course_query: common.queries.school_course_session,
          completed: common.constants.verb_id_completed,
        },
        refId: 'A',
        timeField: 'timestamp',
      },
    ],
    type: 'histogram',
  },
  gridPos={ x: 6, y: 6, w: 6, h: 9 }
)
