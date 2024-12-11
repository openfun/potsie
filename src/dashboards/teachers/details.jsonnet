// Video details dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local teachers_common = import 'common.libsonnet';
local text = grafana.text;
local utils = import '../utils.libsonnet';
local common = import '../common.libsonnet';

dashboard.new(
  'Course video details',
  tags=[common.tags.xapi, common.tags.video, common.tags.teacher],
  editable=false,
  time_from='now-90d',
  uid=common.uids.course_video_details,
)
.addLink(teachers_common.link.teacher)
.addTemplate(teachers_common.templates.edx_course_key)
.addTemplate(teachers_common.templates.video_iri)
.addTemplate(teachers_common.templates.video_id)
.addTemplate(teachers_common.templates.video_title)
.addPanel(
  row.new(title='Video information', collapse=false),
  gridPos={ x: 0, y: 0, w: 24, h: 1 }
)
.addPanel(
  text.new(
    title='Title',
    content=|||
      # ${VIDEO_TITLE}
    |||
  ),
  gridPos={ x: 0, y: 1, w: 12, h: 4.5 }
)
.addPanel(
  statPanel.new(
    title='Duration',
    description=|||
      Duration of the video (in seconds).
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='max',
    unit='none',
    fields='/^Max context\\.extensions.https://w3id.org/xapi/video/extensions/length$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND verb.id:"%(verb_initialized)s"' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        verb_initialized: common.fields.verb.id.initialized,
      },
      metrics=[utils.metrics.max(common.fields.context.extensions.length)],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 1, w: 6, h: 4.5 },
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
      query='%(course_key)s AND %(video_iri)s AND verb.id:"%(verb_initialized)s"' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        verb_initialized: common.fields.verb.id.initialized,
      },
      metrics=[utils.metrics.max(common.fields.context.extensions.completion_threshold)],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 18, y: 1, w: 6, h: 4.5 },
)
.addPanel(
  row.new(title='Views statistics', collapse=false),
  gridPos={ x: 0, y: 5.5, w: 24, h: 1 }
)
.addPanel(
  graphPanel.new(
    title='Daily statistics',
    description=|||
      Daily views, complete views and downloads of the video.

      A view is counted when the user has clicked the play button in the interface
      in the first %(view_count_threshold)s seconds of the video.

      A complete view is counted when the user has viewed the video
      at least up to the completion threshold.

      A download is counted when the user downloads the video files from Marsha.
    ||| % { view_count_threshold: teachers_common.constants.view_count_threshold },
    datasource=common.datasources.lrs,
  ).addTarget(
    elasticsearch.target(
      alias='Views',
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        views: teachers_common.queries.views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram(min_doc_count=0)],
      timeField='@timestamp'
    )
  ).addTarget(
    elasticsearch.target(
      alias='Complete views',
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        complete_views: teachers_common.queries.complete_views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram(min_doc_count=0)],
      timeField='@timestamp'
    )
  ).addTarget(
    elasticsearch.target(
      alias='Downloads',
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram(min_doc_count=0)],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 6.5, w: 12, h: 9 }
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
      query='%(course_key)s AND %(video_iri)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        views: teachers_common.queries.views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 6.5, w: 6, h: 3 }
)
.addPanel(
  statPanel.new(
    title='Viewers',
    description=|||
      Number of enrolled users that played at least one video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        views: teachers_common.queries.views,
      },
      metrics=[utils.metrics.cardinality(common.fields.actor.account.name)],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.context.contextActivities.parent.id,
          settings: {
            order: 'desc',
            orderBy: '_count',
            min_doc_count: '1',
            size: '0',
          },
          type: 'terms',
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 18, y: 6.5, w: 6, h: 3 }
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
      query='%(course_key)s AND %(video_iri)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        complete_views: teachers_common.queries.complete_views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 9.5, w: 6, h: 3 },
)
.addPanel(
  statPanel.new(
    title='Complete viewers',
    description=|||
      Number of users that have viewed completely the video at least once.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        complete_views: teachers_common.queries.complete_views,
      },
      metrics=[utils.metrics.cardinality(common.fields.actor.account.name)],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.context.contextActivities.parent.id,
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
  gridPos={ x: 18, y: 9.5, w: 6, h: 3 },
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
      query='%(course_key)s AND %(video_iri)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 12.5, w: 6, h: 3 }
)
.addPanel(
  statPanel.new(
    title='Downloaders',
    description=|||
      Number of users that have downloaded the video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.cardinality(common.fields.actor.account.name)],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.context.contextActivities.parent.id,
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
  gridPos={ x: 18, y: 12.5, w: 6, h: 3 },
)
.addPanel(
  row.new(title='Event distributions', collapse=false),
  gridPos={ x: 0, y: 15.5, w: 24, h: 1 }
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
            field: common.fields.result.extensions.time,
            id: '2',
            settings: {
              interval: teachers_common.constants.event_group_interval,
              min_doc_count: '1',
            },
            type: 'histogram',
          },
          {
            field: common.fields.verb.display.en_US,
            id: '3',
            settings: {
              min_doc_count: '0',
              order: 'asc',
              orderBy: '_term',
              size: '0',
            },
            type: 'terms',
          },
        ],
        metrics: [utils.metrics.count],
        query: '%(course_key)s AND %(video_iri)s' % {
          course_key: teachers_common.queries.course_key,
          video_iri: teachers_common.queries.video_iri,
        },
        refId: 'A',
        timeField: '@timestamp',
      },
    ],
    type: 'potsie-stackedbarchart-panel',
  },
  gridPos={ x: 0, y: 16.5, w: 24, h: 9 }
)
.addPanel(
  graphPanel.new(
    title='Time distribution of video events',
    datasource=common.datasources.lrs,
    bars=true,
    lines=false,
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: 'verb',
          field: 'verb.display.en-US.keyword',
          type: 'terms',
          settings: {
            order: 'asc',
            orderBy: '_term',
            min_doc_count: '0',
            size: '0',
          },
        },
        utils.aggregations.date_histogram(interval='1h', min_doc_count=0),
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 24.5, w: 12, h: 9 }
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
      query='%(course_key)s AND %(video_iri)s' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: '2',
          field: common.fields.verb.display.en_US,
          type: 'terms',
          settings: {
            order: 'asc',
            orderBy: '_term',
            min_doc_count: '0',
            size: '0',
          },
        },
        utils.aggregations.date_histogram(min_doc_count=0),
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 24.5, w: 12, h: 9 }
)
.addPanel(
  row.new(title='Video player interactions', collapse=false),
  gridPos={ x: 0, y: 33.5, w: 24, h: 1 },
)
.addPanel(
  statPanel.new(
    title='Subtitle activation',
    description=|||
      The number of learners who have activated the subtitles.
    |||,
    datasource=common.datasources.lrs,
    fields=common.fields.actor.account.name,
    graphMode='none',
    reducerFunction='count',
    unit='none',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(interactions)s AND %(subtitle_enabled)s:true' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        interactions: teachers_common.queries.interactions,
        subtitle_enabled: utils.functions.single_escape_string(common.fields.context.extensions.subtitle_enabled),
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.actor.account.name,
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
  gridPos={ x: 0, y: 34.5, w: 4, h: 6 }
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
        query: '%(course_key)s AND %(video_iri)s AND %(interactions)s' % {
          course_key: teachers_common.queries.course_key,
          video_iri: teachers_common.queries.video_iri,
          interactions: teachers_common.queries.interactions,
        },
        metrics: [utils.metrics.cardinality(common.fields.actor.account.name)],
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
            field: common.fields.context.extensions.subtitle_language,
          },
        ],
        timeField: '@timestamp',
      },
    ],
    datasource: common.datasources.lrs,
  },
  gridPos={ x: 4, y: 34.5, w: 4, h: 6 }
)
.addPanel(
  statPanel.new(
    title='Full screen activation',
    description=|||
      The number of learners who have switched to full screen.
    |||,
    datasource=common.datasources.lrs,
    fields=common.fields.actor.account.name,
    graphMode='none',
    reducerFunction='count',
    unit='none',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(video_iri)s AND %(interactions)s AND %(full_screen)s:true' % {
        course_key: teachers_common.queries.course_key,
        video_iri: teachers_common.queries.video_iri,
        interactions: teachers_common.queries.interactions,
        full_screen: utils.functions.single_escape_string(common.fields.context.extensions.full_screen),
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.actor.account.name,
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
  gridPos={ x: 8, y: 34.5, w: 4, h: 6 }
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
        query: '%(course_key)s AND %(video_iri)s AND %(interactions)s' % {
          course_key: teachers_common.queries.course_key,
          video_iri: teachers_common.queries.video_iri,
          interactions: teachers_common.queries.interactions,
        },
        metrics: [utils.metrics.cardinality(common.fields.actor.account.name)],
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
            field: common.fields.context.extensions.speed,
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
              fieldName: common.fields.context.extensions.speed,
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
  gridPos={ x: 12, y: 34.5, w: 4, h: 6 }
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
        query: '%(course_key)s AND %(video_iri)s AND %(interactions)s' % {
          course_key: teachers_common.queries.course_key,
          video_iri: teachers_common.queries.video_iri,
          interactions: teachers_common.queries.interactions,
        },
        metrics: [utils.metrics.cardinality(common.fields.actor.account.name)],
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
            field: common.fields.context.extensions.quality,
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
              targetField: common.fields.context.extensions.quality,
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
              fieldName: common.fields.context.extensions.quality,
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
  gridPos={ x: 16, y: 34.5, w: 4, h: 6 }
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
            options: common.fields.context.extensions.volume,
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
        query: '%(course_key)s AND %(video_iri)s AND %(interactions)s' % {
          course_key: teachers_common.queries.course_key,
          video_iri: teachers_common.queries.video_iri,
          interactions: teachers_common.queries.interactions,
        },
        metrics: [utils.metrics.cardinality(common.fields.actor.account.name)],
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
            field: common.fields.context.extensions.volume,
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
              targetField: common.fields.context.extensions.volume,
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
              fieldName: common.fields.context.extensions.volume,
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
  gridPos={ x: 20, y: 34.5, w: 4, h: 6 }
)
