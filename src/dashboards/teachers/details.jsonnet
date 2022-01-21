// Video details dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local teachers_common = import 'common.libsonnet';
local common = import '../common.libsonnet';

dashboard.new(
  'Details',
  tags=[common.tags.xapi, common.tags.video, common.tags.teacher],
  editable=false,
  time_from='now-90d',
)
.addTemplate(teachers_common.templates.edx_course_key)
.addTemplate(teachers_common.templates.school)
.addTemplate(teachers_common.templates.course)
.addTemplate(teachers_common.templates.session)
.addTemplate(teachers_common.templates.video)
.addPanel(
  row.new(title='Views metrics', collapse=false),
  gridPos={ x: 0, y: 0, w: 24, h: 1 }
)
.addPanel(
  statPanel.new(
    title='Views',
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first %(view_count_threshold)s seconds of the video.

      Note that we count additional `views` each time the user plays or resumes
      the video during the first seconds of the video. This time range is
      controlled by the `View count threshold` variable.
    ||| % { view_count_threshold: teachers_common.constants.view_count_threshold },
    datasource=common.datasources.lrs,
    reducerFunction='sum',
    graphMode='none',
    unit='none'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
        video_query: teachers_common.queries.video_id,
        verb_played: common.verb_ids.played,
        time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
        view_count_threshold: teachers_common.constants.view_count_threshold,
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'date',
          field: '@timestamp',
          type: 'date_histogram',
          settings: {
            interval: '1d',
            min_doc_count: '0',
            trimEdges: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 0, y: 1, w: 4.8, h: 4.5 }
)
.addPanel(
  statPanel.new(
    title='Unique views',
    description=|||
      Unique views are views aggregated by users: each user can generate
      at most one view in this metric.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_played)s"' % {
        video_query: teachers_common.queries.video_id,
        verb_played: common.verb_ids.played,
      },
      metrics=[common.metrics.cardinality(common.fields.actor_account_name)],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.actor_account_name,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            min_doc_count: '0',
            size: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 4.8, y: 1, w: 4.8, h: 3 }
)
.addPanel(
  statPanel.new(
    title='Complete views',
    description=|||
      Total number of complete views of selected video. A view is considered as complete
      when the completion threshold of the video has been reached.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_completed)s"' % {
        video_query: teachers_common.queries.video_id,
        verb_completed: common.verb_ids.completed,
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: '5',
          type: 'date_histogram',
          settings: {
            interval: 'auto',
            min_doc_count: '0',
            trimEdges: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 0, y: 4, w: 4.8, h: 4.5 },
)
.addPanel(
  statPanel.new(
    title='Unique complete views',
    description=|||
      Total number of unique complete views of selected video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_completed)s"' % {
        video_query: teachers_common.queries.video_id,
        verb_completed: common.verb_ids.completed,
      },
      metrics=[common.metrics.cardinality(common.fields.actor_account_name)],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.actor_account_name,
          type: 'terms',
          settings: {
            min_doc_count: '0',
            size: '0',
            order: 'desc',
            orderBy: '_count',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 4.8, y: 3, w: 4.8, h: 3 },
)
.addPanel(
  statPanel.new(
    title='Completion threshold',
    description=|||
      Ratio of the video that needs to be seen to consider the video as completed.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='max',
    unit='none',
    fields='/^Max context\\.extensions.https://w3id.org/xapi/video/extensions/completion\\-threshold$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_initialized)s"' % {
        video_query: teachers_common.queries.video_id,
        verb_initialized: common.verb_ids.initialized,
      },
      metrics=[common.metrics.max(teachers_common.fields.context_extensions_completion_threshold)],
      bucketAggs=[
        {
          id: '2',
          type: 'date_histogram',
          settings: {
            interval: 'auto',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 4.8, y: 5, w: 4.8, h: 3 },
)
.addPanel(
  graphPanel.new(
    title='Daily views',
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first %(view_count_threshold)s seconds of the video.
    ||| % { view_count_threshold: teachers_common.constants.view_count_threshold },
    datasource=common.datasources.lrs,
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
        video_query: teachers_common.queries.video_id,
        verb_played: common.verb_ids.played,
        time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
        view_count_threshold: teachers_common.constants.view_count_threshold,
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'date',
          field: '@timestamp',
          type: 'date_histogram',
          settings: {
            interval: '1d',
            min_doc_count: '0',
            trimEdges: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 9.6, y: 1, w: 14.4, h: 9 }
)
.addPanel(
  row.new(title='Event distributions', collapse=false),
  gridPos={ x: 0, y: 7, w: 24, h: 1 }
)
.addPanel(
  {
    title: 'Event distribution during the video',
    description: |||
      We divide the video duration into equal intervals and for each interval display
      its event distribution.
      The interval size is controlled by the `Event group interval` variable.
    |||,
    datasource: 'lrs',
    options: {
      xLabel: 'Video timeline (seconds)',
      yLabel: '# events by type',
      isXContinuous: true,
      numberOfBins: 20,
    },
    targets: [
      {
        bucketAggs: [
          {
            field: teachers_common.fields.result_extensions_time,
            id: '2',
            settings: {
              interval: teachers_common.constants.event_group_interval,
              min_doc_count: '1',
            },
            type: 'histogram',
          },
          {
            field: teachers_common.fields.verb_display_en_us,
            id: '3',
            settings: {
              min_doc_count: '0',
              order: 'desc',
              orderBy: '_term',
              size: '0',
            },
            type: 'terms',
          },
        ],
        metrics: [common.metrics.count],
        query: teachers_common.queries.video_id,
        refId: 'A',
        timeField: 'timestamp',
      },
    ],
    type: 'potsie-stackedbarchart-panel',
  },
  gridPos={ x: 0, y: 8, w: 24, h: 9 }
)
.addPanel(
  graphPanel.new(
    title='Verbs',
    datasource=common.datasources.lrs,
    bars=true,
    lines=false,
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query=teachers_common.queries.video_id,
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'verb',
          field: 'verb.display.en-US.keyword',
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            min_doc_count: '0',
            size: '0',
          },
        },
        {
          id: 'date',
          field: '@timestamp',
          type: 'date_histogram',
          settings: {
            interval: '1h',
            min_doc_count: '0',
            trimEdges: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 0, y: 17, w: 12, h: 9 }
)
.addPanel(
  graphPanel.new(
    title='Course video events distribution',
    description=|||
      Distribution of events according to their type.
    |||,
    datasource=common.datasources.lrs,
    bars='true',
    lines='false',
    x_axis_mode='series',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s' % {
        video_query: teachers_common.queries.video_id,
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: '2',
          field: teachers_common.fields.verb_display_en_us,
          type: 'terms',
          settings: {
            order: 'asc',
            orderBy: '_term',
            min_doc_count: '0',
            size: '0',
          },
        },
        {
          id: '3',
          type: 'date_histogram',
          field: '@timestamp',
          settings: {
            interval: 'auto',
            min_doc_count: '0',
            trimEdges: '0',
          },
        },
      ],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 12, y: 17, w: 12, h: 9 }
)
