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
  'Course video details',
  tags=[common.tags.xapi, common.tags.video, common.tags.teacher],
  editable=false,
  time_from='now-90d',
)
.addLink(teachers_common.link.teacher)
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
      query=teachers_common.queries.views,
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'date',
          field: '@timestamp',
          settings: {
            interval: '1d',
            min_doc_count: '0',
            trimEdges: '0',
          },
          type: 'date_histogram',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 1, w: 4.8, h: 3 }
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
      query=teachers_common.queries.views,
      metrics=[common.metrics.cardinality(common.fields.actor_account_name)],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.actor_account_name,
          settings: {
            order: 'desc',
            orderBy: '_count',
            min_doc_count: '0',
            size: '0',
          },
          type: 'terms',
        },
      ],
      timeField='@timestamp'
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
      query=teachers_common.queries.complete_views,
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: '5',
          field: '@timestamp',
          settings: {
            interval: 'auto',
            min_doc_count: '0',
            trimEdges: '0',
          },
          type: 'date_histogram',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 3, w: 4.8, h: 3 },
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
      query=teachers_common.queries.complete_views,
      metrics=[common.metrics.cardinality(common.fields.actor_account_name)],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.actor_account_name,
          settings: {
            min_doc_count: '0',
            size: '0',
            order: 'desc',
            orderBy: '_count',
          },
          type: 'terms',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 4.8, y: 3, w: 4.8, h: 3 },
)
.addPanel(
  statPanel.new(
    title='Downloads',
    description=|||
      Number of video downloads.
    |||,
    datasource=common.datasources.lrs,
    reducerFunction='sum',
    graphMode='none',
    unit='none'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_downloaded)s"' % {
        video_query: teachers_common.queries.video_id,
        verb_downloaded: common.verb_ids.downloaded,
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: 'date',
          field: '@timestamp',
          settings: {
            interval: '1d',
            min_doc_count: '0',
            trimEdges: '0',
          },
          type: 'date_histogram',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 5, w: 4.8, h: 3 }
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
      timeField='@timestamp'
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
      query=teachers_common.queries.views,
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
      timeField='@timestamp'
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
        timeField: '@timestamp',
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
      timeField='@timestamp'
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
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 17, w: 12, h: 9 }
)
.addPanel(
  row.new(title='Interaction activities', collapse=false),
  gridPos={ x: 0, y: 26, w: 24, h: 1 },
)
.addPanel(
  statPanel.new(
    title='Subtitle activation',
    description=|||
      The number of learners who have activated the subtitles.
    |||,
    datasource=common.datasources.lrs,
    fields=common.fields.actor_account_name,
    graphMode='none',
    reducerFunction='count',
    unit='none',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"interacted" AND %(subtitle_enabled)s:true' % {
        video_query: teachers_common.queries.video_id,
        subtitle_enabled: common.utils.single_escape_string(common.fields.subtitle_enabled),
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.actor_account_name,
          settings: {
            min_doc_count: '1',
            size: '0',
            order: 'desc',
            orderBy: '_count',
          },
          type: 'terms',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 26, w: 4, h: 6 }
).addPanel(
  {
    type: 'barchart',
    title: 'Selected subtitle language',
    description: |||
      The distribution of subtitle languages chosen by users when it is activated.
    |||,
    options: {
      legend: {
        displayMode: 'hidden',
      },
    },
    fieldConfig: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Unique Count',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Users',
            },
          ],
        },
      ],
    },
    targets: [
      {
        datasource: common.datasources.lrs,
        query: '%(video_query)s AND verb.id:"interacted"' % {
          video_query: teachers_common.queries.video_id,
        },
        metrics: [common.metrics.cardinality(common.fields.actor_account_name)],
        bucketAggs: [
          {
            id: '2',
            type: 'terms',
            settings: {
              min_doc_count: '1',
              size: '10',
              order: 'desc',
              orderBy: '_term',
            },
            field: common.fields.subtitle_language,
          },
        ],
        timeField: '@timestamp',
      },
    ],
    datasource: common.datasources.lrs,
  },
  gridPos={ x: 4, y: 26, w: 4, h: 6 }
)
.addPanel(
  statPanel.new(
    title='Full screen activation',
    description=|||
      The number of learners who have switched to full screen.
    |||,
    datasource=common.datasources.lrs,
    fields=common.fields.actor_account_name,
    graphMode='none',
    reducerFunction='count',
    unit='none',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"interacted" AND %(full_screen)s:true' % {
        video_query: teachers_common.queries.video_id,
        full_screen: common.utils.single_escape_string(common.fields.full_screen),
      },
      metrics=[common.metrics.count],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.actor_account_name,
          settings: {
            min_doc_count: '1',
            size: '0',
            order: 'desc',
            orderBy: '_count',
          },
          type: 'terms',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 8, y: 26, w: 4, h: 6 }
).addPanel(
  {
    type: 'barchart',
    title: 'Changed video speed',
    description: |||
      The distribution of changed video speed (compared to default).
      By default the video speed is set to `1x`.
    |||,
    options: {
      legend: {
        displayMode: 'hidden',
      },
    },
    fieldConfig: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Unique Count',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Users',
            },
          ],
        },
      ],
    },
    targets: [
      {
        datasource: common.datasources.lrs,
        query: '%(video_query)s AND verb.id:"interacted"' % {
          video_query: teachers_common.queries.video_id,
        },
        metrics: [common.metrics.cardinality(common.fields.actor_account_name)],
        bucketAggs: [
          {
            id: '2',
            type: 'terms',
            settings: {
              min_doc_count: '1',
              size: '10',
              order: 'desc',
              orderBy: '_term',
            },
            field: common.fields.speed,
          },
        ],
        timeField: '@timestamp',
      },
    ],
    datasource: common.datasources.lrs,
    transformations: [
      {
        id: 'filterByValue',
        options: {
          filters: [
            {
              fieldName: common.fields.speed,
              config: {
                id: 'equal',
                options: {
                  value: '1x',
                },
              },
            },
          ],
          type: 'exclude',
          match: 'all',
        },
      },
    ],
  },
  gridPos={ x: 12, y: 26, w: 4, h: 6 }
).addPanel(
  {
    type: 'barchart',
    title: 'Changed video quality',
    description: |||
      The distribution of video quality chosen by the users.
      By default, the video quality is set to `480`.
    |||,
    options: {
      legend: {
        displayMode: 'hidden',
      },
    },
    fieldConfig: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Unique Count',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Users',
            },
          ],
        },
      ],
    },
    targets: [
      {
        datasource: common.datasources.lrs,
        query: '%(video_query)s AND verb.id:"interacted"' % {
          video_query: teachers_common.queries.video_id,
        },
        metrics: [common.metrics.cardinality(common.fields.actor_account_name)],
        bucketAggs: [
          {
            id: '2',
            type: 'terms',
            settings: {
              min_doc_count: '1',
              size: '10',
              order: 'desc',
              orderBy: '_term',
            },
            field: common.fields.quality,
          },
        ],
        timeField: '@timestamp',
      },
    ],
    datasource: common.datasources.lrs,
    transformations: [
      {
        id: 'convertFieldType',
        options: {
          conversions: [
            {
              targetField: common.fields.quality,
              destinationType: 'string',
            },
          ],
        },
      },
      {
        id: 'filterByValue',
        options: {
          filters: [
            {
              fieldName: common.fields.quality,
              config: {
                id: 'equal',
                options: {
                  value: '480',
                },
              },
            },
          ],
          type: 'exclude',
          match: 'all',
        },
      },
    ],
  },
  gridPos={ x: 16, y: 26, w: 4, h: 6 }
).addPanel(
  {
    type: 'barchart',
    title: 'Changed video volume',
    description: |||
      The number of users who chosed to reduce the video volume or completely mute the video.
      By default, the volume is set to `1`.
    |||,
    options: {
      legend: {
        displayMode: 'hidden',
      },
    },
    fieldConfig: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: common.fields.volume,
          },
          properties: [
            {
              id: 'mappings',
              value: [
                {
                  type: 'range',
                  options: {
                    from: -0.01,
                    to: 0.05,
                    result: {
                      text: 'Mute',
                      index: 1,
                    },
                  },
                },
                {
                  type: 'range',
                  options: {
                    from: 0.05000000000000000000001,
                    to: 0.999,
                    result: {
                      text: 'Turned down',
                      index: 0,
                    },
                  },
                },
              ],
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Unique Count',
          },
          properties: [
            {
              id: 'displayName',
              value: 'Users',
            },
          ],
        },
      ],
    },
    targets: [
      {
        datasource: common.datasources.lrs,
        query: '%(video_query)s AND verb.id:"interacted"' % {
          video_query: teachers_common.queries.video_id,
        },
        metrics: [common.metrics.cardinality(common.fields.actor_account_name)],
        bucketAggs: [
          {
            id: '2',
            type: 'terms',
            settings: {
              min_doc_count: '1',
              size: '10',
              order: 'desc',
              orderBy: '_term',
            },
            field: common.fields.volume,
          },
        ],
        timeField: '@timestamp',
      },
    ],
    datasource: common.datasources.lrs,
    transformations: [
      {
        id: 'convertFieldType',
        options: {
          conversions: [
            {
              targetField: common.fields.volume,
              destinationType: 'string',
            },
          ],
        },
      },
      {
        id: 'filterByValue',
        options: {
          filters: [
            {
              fieldName: common.fields.volume,
              config: {
                id: 'equal',
                options: {
                  value: '1',
                },
              },
            },
          ],
          type: 'exclude',
          match: 'all',
        },
      },
    ],
  },
  gridPos={ x: 20, y: 26, w: 4, h: 6 }
)
