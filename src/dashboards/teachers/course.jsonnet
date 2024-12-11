// Video course dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local sql = grafana.sql;
local teachers_common = import 'common.libsonnet';
local text = grafana.text;
local common = import '../common.libsonnet';
local utils = import '../utils.libsonnet';

dashboard.new(
  'Course videos overview',
  tags=[common.tags.xapi, common.tags.video, common.tags.teacher],
  editable=false,
  time_from='now-90d',
  uid=common.uids.course_video_overview,
)
.addLink(teachers_common.link.teacher)
.addTemplate(teachers_common.templates.edx_course_key)
.addTemplate(teachers_common.templates.course_title)
.addTemplate(teachers_common.templates.start_date)
.addTemplate(teachers_common.templates.end_date)
.addTemplate(teachers_common.templates.course_videos_ids)
.addTemplate(teachers_common.templates.course_videos_iris)
.addPanel(
  row.new(title='Course information', collapse=false),
  gridPos={ x: 0, y: 0, w: 24, h: 1 }
)
.addPanel(
  text.new(
    title='Title',
    content=|||
      # ${COURSE_TITLE}
    |||
  ),
  gridPos={ x: 0, y: 1, w: 12, h: 4.5 }
)
.addPanel(
  text.new(
    title='Session dates',
    content=|||
      ## Started: ${START_DATE}
      ## Ended: ${END_DATE}
    |||
  ),
  gridPos={ x: 12, y: 1, w: 4, h: 4.5 }
)
.addPanel(
  statPanel.new(
    title='Enrollments',
    description=|||
      Total number of enrolled users for the course session.

      Enrolled users comprise learners and instructors.
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
  gridPos={ x: 16, y: 1, w: 4, h: 4.5 }
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
      query='%(course_key)s AND %(course_videos)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: 'video',
          field: common.fields.object.id,
          type: 'terms',
          settings: {
            min_doc_count: '1',
            size: '0',
            order: 'desc',
            orderBy: '_term',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 20, y: 1, w: 4, h: 4.5 }
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
      query='%(course_key)s AND %(course_videos)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
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
      query='%(course_key)s AND %(course_videos)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
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
      query='%(course_key)s AND %(course_videos)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram(min_doc_count=0)],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 0, y: 6.5, w: 12, h: 12 }
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
      query='%(course_key)s AND %(course_videos)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        views: teachers_common.queries.views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 6.5, w: 4, h: 4 }
)
.addPanel(
  statPanel.new(
    title='Viewers',
    description=|||
      Number of users that played at least one video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(course_videos)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        views: teachers_common.queries.views,
      },
      metrics=[utils.metrics.cardinality(common.fields.actor.account.name)],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.context.contextActivities.parent.id,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            size: '0',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 16, y: 6.5, w: 4, h: 4 }
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
      query='%(course_key)s AND %(course_videos)s AND %(views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        views: teachers_common.queries.views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: 'video',
          field: common.fields.object.id,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            size: '0',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 20, y: 6.5, w: 4, h: 4 }
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
      query='%(course_key)s AND %(course_videos)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        complete_views: teachers_common.queries.complete_views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 10.5, w: 4, h: 4 }
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
      query='%(course_key)s AND %(course_videos)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        complete_views: teachers_common.queries.complete_views,
      },
      metrics=[utils.metrics.cardinality(common.fields.actor.account.name)],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.context.contextActivities.parent.id,
          type: 'terms',
          settings: {
            size: '0',
            order: 'desc',
            orderBy: '_count',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 16, y: 10.5, w: 4, h: 4 }
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
      query='%(course_key)s AND %(course_videos)s AND %(complete_views)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        complete_views: teachers_common.queries.complete_views,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.object.id,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            size: '0',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 20, y: 10.5, w: 4, h: 4 }
)
.addPanel(
  statPanel.new(
    title='Downloads',
    description=|||
      Total number of downloads of selected course session videos.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(course_videos)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[utils.aggregations.date_histogram()],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 12, y: 14.5, w: 4, h: 4 }
)
.addPanel(
  statPanel.new(
    title='Downloaders',
    description=|||
      Number of users that have downloaded at least one video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(course_videos)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.cardinality(common.fields.actor.account.name)],
      bucketAggs=[
        {
          id: '5',
          field: common.fields.context.contextActivities.parent.id,
          type: 'terms',
          settings: {
            size: '0',
            order: 'desc',
            orderBy: '_count',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 16, y: 14.5, w: 4, h: 4 }
)
.addPanel(
  statPanel.new(
    title='Average video downloads',
    description=|||
      Average number of downloads per video.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='mean',
    unit='none',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(course_key)s AND %(course_videos)s AND %(downloads)s' % {
        course_key: teachers_common.queries.course_key,
        course_videos: teachers_common.queries.course_videos,
        downloads: teachers_common.queries.downloads,
      },
      metrics=[utils.metrics.count],
      bucketAggs=[
        {
          id: 'name',
          field: common.fields.object.id,
          type: 'terms',
          settings: {
            order: 'desc',
            orderBy: '_count',
            size: '0',
          },
        },
      ],
      timeField='@timestamp'
    )
  ),
  gridPos={ x: 20, y: 14.5, w: 4, h: 4 }
)
.addPanel(
  row.new(title='Videos statistics', collapse=false),
  gridPos={ x: 0, y: 18.5, w: 24, h: 1 }
)
.addPanel(
  {
    type: 'table',
    title: 'Course run video views',
    transformations: [
      {
        id: 'seriesToColumns',
        options: {
          byField: 'object.id',
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
            options: 'object.id',
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
                  url: '/d/%(course_video_details_uid)s/details?orgId=1&${EDX_COURSE_KEY:queryparam}&var-VIDEO_IRI=${__value.text}' % {
                    course_video_details_uid: common.uids.course_video_details,
                  },
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
            field: common.fields.object.id,
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
        query: '%(course_key)s AND %(course_videos)s AND %(views)s' % {
          course_key: teachers_common.queries.course_key,
          course_videos: teachers_common.queries.course_videos,
          views: teachers_common.queries.views,
        },
        refId: 'Videos views query',
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
        rawSql: "SELECT 'uuid://' || id AS \"object.id\",title FROM video where id IN (${COURSE_VIDEOS_IDS:sqlstring})",
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
      {
        bucketAggs: [
          {
            id: 'name',
            field: common.fields.object.id,
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
        metrics: [utils.metrics.cardinality(common.fields.actor.account.name)],
        query: '%(course_key)s AND %(course_videos)s AND %(views)s' % {
          course_key: teachers_common.queries.course_key,
          course_videos: teachers_common.queries.course_videos,
          views: teachers_common.queries.views,
        },
        refId: 'Videos unique views query',
        timeField: '@timestamp',
      },
      {
        bucketAggs: [
          {
            id: 'name',
            field: common.fields.object.id,
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
        metrics: [utils.metrics.count],
        query: '%(course_key)s AND %(course_videos)s AND %(complete_views)s' % {
          course_key: teachers_common.queries.course_key,
          course_videos: teachers_common.queries.course_videos,
          complete_views: teachers_common.queries.complete_views,
        },
        refId: 'Videos complete views query',
        timeField: '@timestamp',
      },
      {
        bucketAggs: [
          {
            field: common.fields.object.id,
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
        metrics: [utils.metrics.cardinality(common.fields.actor.account.name)],
        query: '%(course_key)s AND %(course_videos)s AND %(complete_views)s' % {
          course_key: teachers_common.queries.course_key,
          course_videos: teachers_common.queries.course_videos,
          complete_views: teachers_common.queries.complete_views,
        },
        refId: 'Videos complete unique views query',
        timeField: '@timestamp',
      },
    ],
  },
  gridPos={ x: 0, y: 19.5, w: 24, h: 12 }
)
