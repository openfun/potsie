// Video course dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local barGaugePanel = grafana.barGaugePanel;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local sql = grafana.sql;
local teachers_common = import 'common.libsonnet';
local text = grafana.text;
local common = import '../common.libsonnet';


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
.addTemplate(teachers_common.templates.course_video_ids)
.addTemplate(teachers_common.templates.course_video_ids_with_uuid)
.addPanel(
  text.new(
    title='Course information',
    content=|||
      # ${TITLE}
      ## Started: ${START_DATE} 
      ## Ended: ${END_DATE}
    |||
  ),
  gridPos={ x: 0, y: 6, w: 4, h: 9 }
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
  gridPos={ x: 4, y: 9, w: 4, h: 9 }
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
  gridPos={ x: 8, y: 9, w: 4, h: 9 }
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
  gridPos={ x: 12, y: 9, w: 12, h: 9 }
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
  gridPos={ x: 12, y: 18, w: 4, h: 4.5 }
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
      query='(%(course_query)s) AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
        course_query: teachers_common.queries.course_query,
        verb_played: common.verb_ids.played,
        time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
        view_count_threshold: teachers_common.constants.view_count_threshold,
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
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 16, y: 18, w: 4, h: 4.5 }
)
.addPanel(
  statPanel.new(
    title='Average video views',
    description=|||
      Average number of views per video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='mean',
    unit='none',
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
          id: 'video',
          field: common.fields.video_id,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            min_doc_count: '0',
            size: '0',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 20, y: 18, w: 4, h: 4.5 }
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
  gridPos={ x: 12, y: 22.5, w: 4, h: 4.5 }
)
.addPanel(
  statPanel.new(
    title='Unique complete views',
    description=|||
      Total number of complete views of selected course session videos.
      Note that a view is considered as complete when the completion threshold
      of the video has been reached.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='(%(course_query)s) AND verb.id:"%(verb_completed)s"' % {
        course_query: teachers_common.queries.course_query,
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
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 16, y: 22.5, w: 4, h: 4.5 }
)
.addPanel(
  statPanel.new(
    title='Average complete video views',
    description=|||
      Average number of complete views per video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='mean',
    unit='none',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='(%(course_query)s) AND verb.id:"%(verb_completed)s"' % {
        course_query: teachers_common.queries.course_query,
        verb_completed: common.verb_ids.completed,
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.video_id,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            min_doc_count: '0',
            size: '0',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 20, y: 22.5, w: 4, h: 4.5 }
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
  gridPos={ x: 0, y: 27, w: 12, h: 9 }
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
  gridPos={ x: 0, y: 36, w: 12, h: 9 }
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
  gridPos={ x: 0, y: 44, w: 12, h: 9 }
)
.addPanel(
  {
    type: 'table',
    title: 'Course run video views',
    transformations: [
      {
        id: 'seriesToColumns',
        options: {
          byField: 'object.id.keyword',
        },
      },
    ],
    datasource: {
      type: 'datasource',
      uid: '-- Mixed --',
    },
    fieldConfig: {
      defaults: {
        custom: {
          align: 'auto',
          displayMode: 'auto',
          filterable: false,
        },
      },
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'object.id.keyword',
          },
          properties: [
            {
              id: 'displayName',
              value: 'ID',
            },
            {
              id: 'links',
              value: [
                {
                  targetBlank: true,
                  title: 'View detailled insights about this video',
                  url: '/d/_3iCqpynk/details?orgId=1&var-EDX_COURSE_KEY=${EDX_COURSE_KEY}&var-VIDEO=${__value.text}',
                },
              ],
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'title',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Title',
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Count 1',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Views',
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Unique Count 1',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Unique views',
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Count 2',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Complete views',
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Unique Count 2',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Complete unique views',
            },
          ],
        },
      ],
    },
    options: {
      showHeader: true,
    },
    targets: [
      {
        bucketAggs: [
          {
            field: common.fields.video_id,
            id: '2',
            settings: {
              min_doc_count: '1',
              order: 'asc',
              orderBy: '_count',
              size: '0',
            },
            type: 'terms',
          },
        ],
        datasource: common.datasources.lrs,
        metrics: [
          {
            id: '1',
            type: 'count',
          },
        ],
        query: '(%(course_query)s) AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
          course_query: teachers_common.queries.course_query,
          verb_played: common.verb_ids.played,
          time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
          view_count_threshold: teachers_common.constants.view_count_threshold,
        },
        refId: 'Videos views query',
        timeField: '@timestamp',
      },
      {
        bucketAggs: [
          {
            id: 'name',
            field: common.fields.video_id,
            type: 'terms',
            settings: {
              min_doc_count: '1',
              order: 'desc',
              orderBy: '_count',
              size: '0',
            },
          },
        ],
        datasource: common.datasources.lrs,
        metrics: [common.metrics.cardinality(common.fields.actor_account_name)],
        query: '(%(course_query)s) AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
          course_query: teachers_common.queries.course_query,
          verb_played: common.verb_ids.played,
          time: common.utils.single_escape_string(teachers_common.fields.result_extensions_time),
          view_count_threshold: teachers_common.constants.view_count_threshold,
        },
        refId: 'Videos unique views query',
        timeField: '@timestamp',
      },
      {
        bucketAggs: [
          {
            id: 'name',
            field: common.fields.video_id,
            type: 'terms',
            settings: {
              order: 'desc',
              orderBy: '_count',
              min_doc_count: '1',
              size: '0',
            },
          },
        ],
        datasource: common.datasources.lrs,
        metrics: [common.metrics.count],
        query: '(%(course_query)s) AND verb.id:"%(verb_completed)s"' % {
          course_query: teachers_common.queries.course_query,
          verb_completed: common.verb_ids.completed,
        },
        refId: 'Videos complete views query',
        timeField: '@timestamp',
      },
      {
        bucketAggs: [
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
        datasource: common.datasources.lrs,
        metrics: [common.metrics.cardinality(common.fields.actor_account_name)],
        query: '(%(course_query)s) AND verb.id:"%(verb_completed)s"' % {
          course_query: teachers_common.queries.course_query,
          verb_completed: common.verb_ids.completed,
        },
        refId: 'Videos complete unique views query',
        timeField: '@timestamp',
      },
      {
        bucketAggs: [
          {
            field: '@timestamp',
            id: '2',
            settings: {
              interval: 'auto',
            },
            type: 'date_histogram',
          },
        ],
        datasource: common.datasources.marsha,
        format: 'table',
        hide: false,
        metricColumn: 'none',
        metrics: [
          {
            id: '1',
            type: 'count',
          },
        ],
        query: '',
        rawQuery: true,
        rawSql: "SELECT 'uuid://' || id AS \"object.id.keyword\",title FROM video where id IN (${COURSE_VIDEOS_IDS:sqlstring})",
        refId: 'B',
        select: [
          [
            {
              params: [
                'value',
              ],
              type: 'column',
            },
          ],
        ],
        timeColumn: 'time',
        timeField: '@timestamp',
        where: [
          {
            name: '$__timeFilter',
            type: 'macro',
          },
        ],
      },
    ],
  },
  gridPos={ x: 12, y: 36, w: 12, h: 18 }
)
