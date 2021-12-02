// Video statements dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local common = import '../common.libsonnet';
local video_common = import 'common.libsonnet';


dashboard.new(
  'Statements',
  tags=[common.tags.xapi, common.tags.video, common.tags.staff],
  editable=false
)
.addTemplate(video_common.templates.school)
.addTemplate(video_common.templates.course)
.addTemplate(video_common.templates.session)
.addTemplate(video_common.templates.course_key)
.addTemplate(video_common.templates.statements_interval)
.addPanel(
  statPanel.new(
    title='Statements',
    description=|||
      Total count of statements in the selected time range.
    |||,
    datasource=video_common.datasources.lrs,
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=video_common.datasources.lrs,
      query=video_common.queries.school_course_session,
      metrics=[common.metrics.count],
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
    datasource=video_common.datasources.lrs,
    reducerFunction='count',
  ).addTarget(
    elasticsearch.target(
      datasource=video_common.datasources.lrs,
      query=video_common.queries.school_course_session,
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'video',
          field: video_common.fields.video_id,
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
    datasource=video_common.datasources.lrs,
    bars=true,
    lines=false,
  ).addTarget(
    elasticsearch.target(
      datasource=video_common.datasources.lrs,
      query=video_common.queries.school_course_session,
      metrics=[common.metrics.count],
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
    datasource: video_common.datasources.lrs,
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
            field: video_common.fields.video_id,
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
            field: video_common.fields.result_extensions_length,
            id: '1',
            type: 'max',
          },
        ],
        query: video_common.queries.school_course_session,
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
    datasource: video_common.datasources.lrs,
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
            field: video_common.fields.context_extensions_completion_threshold,
            id: '1',
            type: 'max',
          },
        ],
        query: '%(course_query)s AND verb.id:"%(completed)s"' % {
          course_query: video_common.queries.school_course_session,
          completed: common.verb_ids.completed,
        },
        refId: 'A',
        timeField: 'timestamp',
      },
    ],
    type: 'histogram',
  },
  gridPos={ x: 6, y: 6, w: 6, h: 9 }
)
