local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local barGaugePanel = grafana.barGaugePanel;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

local common = import 'common.libsonnet';


dashboard.new(
  'Course',
  tags=['xAPI', 'video', 'teacher'],
  editable=false
)
.addTemplate(common.templates.school)
.addTemplate(common.templates.course)
.addTemplate(common.templates.session)
.addTemplate(common.templates.view_count_threshold)
.addTemplate(common.templates.statements_interval)
.addPanel(
  statPanel.new(
    title='Views',
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first ${VIEW_COUNT_THRESHOLD} seconds of the video.

      Note that we count additional `views` each time the user plays or resumes
      the video during the first seconds of the video. This time range is
      controlled by the `View count threshold` variable.
    |||,
    datasource=common.constants.lrs,
    graphMode='none',
    reducerFunction='sum'
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query='%(course_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO $VIEW_COUNT_THRESHOLD]' % {
        course_query: common.queries.school_course_session,
        verb_played: common.constants.verb_id_played,
        time: common.utils.single_escape_string(common.fields.result_extensions_time),
      },
      metrics=[common.objects.count_metric],
      bucketAggs=[common.objects.date_histogram('$STATEMENTS_INTERVAL')],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 0, y: 9, w: 6, h: 9 }
)
.addPanel(
  statPanel.new(
    title='Complete views',
    description=|||
      Total number of complete views of videos present in the selected course / session.
      A view is considered as complete when the completion threshold of the video has been reached.
    |||,
    datasource=common.constants.lrs,
    graphMode='none',
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query='%(course_query)s AND verb.id:"%(verb_completed)s"' % {
        course_query: common.queries.school_course_session,
        verb_completed: common.constants.verb_id_completed,
      },
      metrics=[common.objects.count_metric],
      bucketAggs=[common.objects.date_histogram()],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 6, y: 9, w: 6, h: 9 }
)
.addPanel(
  graphPanel.new(
    title='Views by ${STATEMENTS_INTERVAL}',
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first ${VIEW_COUNT_THRESHOLD} seconds of the video.
    |||,
    datasource=common.constants.lrs,
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query='%(course_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO $VIEW_COUNT_THRESHOLD]' % {
        course_query: common.queries.school_course_session,
        verb_played: common.constants.verb_id_played,
        time: common.utils.single_escape_string(common.fields.result_extensions_time),
      },
      metrics=[common.objects.count_metric],
      bucketAggs=[common.objects.date_histogram('$STATEMENTS_INTERVAL')],
      timeField='timestamp'
    )
  ),
  gridPos={ x: 12, y: 9, w: 12, h: 9 }
)
.addPanel(
  {
    title: 'Statements by user',
    description: |||
      The count of statements by user.
      On the X-axis is the number of statements.
      On the Y-axis is the number of users.
    |||,
    datasource: common.constants.lrs,
    fieldConfig: {
      defaults: {
        color: {
          mode: 'palette-classic',
        },
        displayName: 'User',
      },
    },
    options: {
      bucketOffset: 0,
      legend: {
        calcs: ['count', 'max', 'mean'],
        displayMode: 'list',
        placement: 'bottom',
      },
    },
    targets: [
      {
        bucketAggs: [
          {
            field: 'timestamp',
            id: '2',
            settings: {
              interval: '3600000',
              min_doc_count: '1',
            },
            type: 'histogram',
          },
          {
            field: common.fields.actor_account_name,
            id: '3',
            settings: {
              min_doc_count: '1',
              order: 'desc',
              orderBy: '_term',
              size: '0',
            },
            type: 'terms',
          },
        ],
        metrics: [common.objects.count_metric],
        query: common.queries.school_course_session,
        refId: 'A',
        timeField: 'timestamp',
      },
    ],
    transformations: [
      {
        id: 'groupBy',
        options: {
          fields: {
            Count: {
              aggregations: [
                'sum',
              ],
              operation: 'aggregate',
            },
            [common.fields.actor_account_name]: {
              operation: 'groupby',
            },
          },
        },
      },
    ],
    type: 'histogram',
  },
  gridPos={ x: 12, y: 18, w: 12, h: 9 }
)
.addPanel(
  {
    title: 'Completed videos by user',
    description: |||
      The distribution of the number of times users completed videos.
      On the X-axis is the number of completed videos.
      On the Y-axis is the number of users.
    |||,
    datasource: common.constants.lrs,
    fieldConfig: {
      defaults: {
        color: {
          mode: 'palette-classic',
        },
        displayName: 'User',
      },
    },
    options: {
      bucketOffset: 0,
      legend: {
        calcs: ['count', 'max', 'mean'],
        displayMode: 'list',
        placement: 'bottom',
      },
    },
    targets: [
      {
        bucketAggs: [
          {
            field: 'timestamp',
            id: '2',
            settings: {
              interval: '3600000',
              min_doc_count: '1',
            },
            type: 'histogram',
          },
          {
            field: common.fields.actor_account_name,
            id: '3',
            settings: {
              min_doc_count: '1',
              order: 'desc',
              orderBy: '_term',
              size: '0',
            },
            type: 'terms',
          },
        ],
        metrics: [common.objects.count_metric],
        query: '%(course_query)s AND verb.id:"%(completed)s"' % {
          course_query: common.queries.school_course_session,
          completed: common.constants.verb_id_completed,
        },
        refId: 'A',
        timeField: 'timestamp',
      },
    ],
    transformations: [
      {
        id: 'groupBy',
        options: {
          fields: {
            Count: {
              aggregations: [
                'sum',
              ],
              operation: 'aggregate',
            },
            [common.fields.actor_account_name]: {
              operation: 'groupby',
            },
          },
        },
      },
    ],
    type: 'histogram',
  },
  gridPos={ x: 0, y: 27, w: 12, h: 9 }
)
.addPanel(
  barGaugePanel.new(
    title='Views by video',
    description=|||
      The total count of views by video.
    |||,
    datasource=common.constants.lrs,
  ).addTarget(
    elasticsearch.target(
      datasource=common.constants.lrs,
      query='%(course_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO $VIEW_COUNT_THRESHOLD]' % {
        course_query: common.queries.school_course_session,
        verb_played: common.constants.verb_id_played,
        time: common.utils.single_escape_string(common.fields.result_extensions_time),
      },
      metrics=[common.objects.count_metric],
      bucketAggs=[
        {
          field: common.fields.video_id,
          id: '2',
          settings: {
            min_doc_count: '1',
            order: 'desc',
            orderBy: '_count',
            size: '0',
          },
          type: 'terms',
        },
      ],
      timeField='timestamp'
    )
  ) + {
    options: {
      displayMode: 'gradient',
      orientation: 'horizontal',
      reduceOptions: {
        calcs: [
          'lastNotNull',
        ],
        fields: '/^Count$/',
        limit: 500,
        values: true,
      },
      showUnfilled: true,
    },
    fieldConfig: {
      defaults: {
        color: { mode: 'thresholds' },
      },
    },
  },
  gridPos={ x: 0, y: 36, w: 12, h: 9 }
)
