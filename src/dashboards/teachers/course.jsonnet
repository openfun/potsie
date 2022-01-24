// Video course dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local barGaugePanel = grafana.barGaugePanel;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local sql = grafana.sql;
local text = grafana.text;
local common = import '../common.libsonnet';
local teachers_common = import 'common.libsonnet';

dashboard.new(
  'Course videos overview',
  tags=[common.tags.xapi, common.tags.video, common.tags.teacher],
  editable=false,
  time_from='now-90d',
)
.addLink(teachers_common.link.teacher)
.addTemplate(teachers_common.templates.edx_course_key)
.addTemplate(teachers_common.templates.school)
.addTemplate(teachers_common.templates.course)
.addTemplate(teachers_common.templates.session)
.addTemplate(teachers_common.templates.title)
.addTemplate(teachers_common.templates.start_date)
.addTemplate(teachers_common.templates.end_date)
.addPanel(
  text.new(
    title='Course',
    content=|||
      # ${TITLE}
    |||
  ),
  gridPos={ x: 0, y: 6, w: 12, h: 3 }
)
.addPanel(
  statPanel.new(
    title='Videos',
    description=|||
      Total number of videos which had at least one interaction in the selected time range.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='count',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query=teachers_common.queries.course_query,
      metrics=[common.metrics.count],
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
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 9, w: 4, h: 6 }
)
.addPanel(
  statPanel.new(
    title='Enrollments',
    description=|||
      Total number of enrolled students.
    |||,
    datasource=common.datasources.edx_app,
    graphMode='none',
    reducerFunction='sum',
  ).addTarget(
    sql.target(
      datasource=common.datasources.edx_app,
      rawSql=teachers_common.queries.course_enrollments,
      format='table'
    )
  ),
  gridPos={ x: 4, y: 9, w: 4, h: 6 }
)
.addPanel(
  text.new(
    title='Dates',
    content=|||
      ## Started: ${START_DATE} 
      ## Ended: ${END_DATE}
    |||
  ),
  gridPos={ x: 8, y: 9, w: 4, h: 6 }
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
    graphMode='none',
    reducerFunction='sum'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='(%(course_query)s) AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
        course_query: teachers_common.queries.course_query,
        verb_played: common.verb_ids.played,
        time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
        view_count_threshold: teachers_common.constants.view_count_threshold,
      },
      metrics=[common.metrics.count],
      bucketAggs=[common.objects.date_histogram('%(statements_interval)s' % { statements_interval: teachers_common.constants.statements_interval })],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 9, w: 6, h: 9 }
)
.addPanel(
  statPanel.new(
    title='Complete views',
    description=|||
      Total number of complete views of selected course session videos.
      Note that a view is considered as complete when the completion threshold
      of the video has been reached.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='(%(course_query)s) AND verb.id:"%(verb_completed)s"' % {
        course_query: teachers_common.queries.course_query,
        verb_completed: common.verb_ids.completed,
      },
      metrics=[common.metrics.count],
      bucketAggs=[common.objects.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 18, y: 9, w: 6, h: 9 }
)
.addPanel(
  graphPanel.new(
    title='Views by %(statements_interval)s' % { statements_interval: teachers_common.constants.statements_interval },
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first %(view_count_threshold)s seconds of the video.
    ||| % { view_count_threshold: teachers_common.constants.view_count_threshold },
    datasource=common.datasources.lrs,
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='(%(course_query)s) AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
        course_query: teachers_common.queries.course_query,
        verb_played: common.verb_ids.played,
        time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
        view_count_threshold: teachers_common.constants.view_count_threshold,
      },
      metrics=[common.metrics.count],
      bucketAggs=[common.objects.date_histogram('%(statements_interval)s' % { statements_interval: teachers_common.constants.statements_interval })],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 18, w: 12, h: 9 }
)
.addPanel(
  barGaugePanel.new(
    title='Views by video',
    description=|||
      The total count of views by video.
    |||,
    datasource=common.datasources.lrs,
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='(%(course_query)s) AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
        course_query: teachers_common.queries.course_query,
        verb_played: common.verb_ids.played,
        time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
        view_count_threshold: teachers_common.constants.view_count_threshold,
      },
      metrics=[common.metrics.count],
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
      timeField='@timestamp'
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
  gridPos={ x: 12, y: 18, w: 12, h: 9 }
)

.addPanel(
  {
    title: 'Statements by user',
    description: |||
      The count of statements by user.
      On the X-axis is the number of statements.
      On the Y-axis is the number of users.
    |||,
    datasource: common.datasources.lrs,
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
            field: '@timestamp',
            id: '2',
            settings: {
              interval: '1h',
              min_doc_count: '1',
            },
            type: 'date_histogram',
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
        metrics: [common.metrics.count],
        query: teachers_common.queries.course_query,
        refId: 'A',
        timeField: '@timestamp',
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
  gridPos={ x: 12, y: 27, w: 12, h: 9 }
)
.addPanel(
  {
    title: 'Completed videos by user',
    description: |||
      The distribution of the number of times users completed videos.
      On the X-axis is the number of completed videos.
      On the Y-axis is the number of users.
    |||,
    datasource: common.datasources.lrs,
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
            field: '@timestamp',
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
        metrics: [common.metrics.count],
        query: '(%(course_query)s) AND verb.id:"%(completed)s"' % {
          course_query: teachers_common.queries.course_query,
          completed: common.verb_ids.completed,
        },
        refId: 'A',
        timeField: '@timestamp',
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
  gridPos={ x: 0, y: 36, w: 12, h: 9 }
)
