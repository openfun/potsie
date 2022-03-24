// Video dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local marsha_common = import 'common.libsonnet';
local common = import '../common.libsonnet';


dashboard.new(
  'Marsha Light Dashboard',
  tags=[common.tags.xapi, common.tags.video],
  editable=false,
  time_from='now-90d',
)
.addTemplate(marsha_common.templates.edx_course_key)
.addTemplate(marsha_common.templates.school)
.addTemplate(marsha_common.templates.course)
.addTemplate(marsha_common.templates.session)
.addTemplate(marsha_common.templates.video)
.addPanel(
  statPanel.new(
    title='Views',
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first %(view_count_threshold)s seconds of the video.

      Note that we count additional `views` each time the user plays or resumes
      the video during the first seconds of the video.
    ||| % { view_count_threshold: marsha_common.constants.view_count_threshold },
    datasource=common.datasources.lrs,
    reducerFunction='sum',
    graphMode='none',
    unit='none'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query=marsha_common.queries.views,
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
  gridPos={ x: 0, y: 0, w: 4.8, h: 6 }
)
.addPanel(
  statPanel.new(
    title='Complete views',
    description=|||
      A complete view is counted when the user has viewed the video 
      at least up to the completion threshold (usually 95% of the video).
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query=marsha_common.queries.complete_views,
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
  gridPos={ x: 0, y: 6, w: 4.8, h: 6 },
)
.addPanel(
  statPanel.new(
    title='Viewers',
    description=|||
      A viewer is counted when a learner has viewed at least one time, 
      completely or not.
    |||,
    datasource=common.datasources.lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query=marsha_common.queries.views,
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
  gridPos={ x: 4.8, y: 0, w: 4.8, h: 6 }
)
.addPanel(
  statPanel.new(
    title='Downloads',
    description=|||
      A download is counted when the user downloads the video files from Marsha.
    |||,
    datasource=common.datasources.lrs,
    reducerFunction='sum',
    graphMode='none',
    unit='none'
  ).addTarget(
    elasticsearch.target(
      datasource=common.datasources.lrs,
      query='%(video_query)s AND verb.id:"%(verb_downloaded)s"' % {
        video_query: marsha_common.queries.video_id,
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
  gridPos={ x: 4.8, y: 6, w: 4.8, h: 6 }
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
    ||| % { view_count_threshold: marsha_common.constants.view_count_threshold },
    datasource=common.datasources.lrs,
  ).addTarget(
    elasticsearch.target(
      alias='Views',
      datasource=common.datasources.lrs,
      query=marsha_common.queries.views,
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
  ).addTarget(
    elasticsearch.target(
      alias='Complete views',
      datasource=common.datasources.lrs,
      query=marsha_common.queries.complete_views,
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
  ).addTarget(
    elasticsearch.target(
      alias='Downloads',
      datasource=common.datasources.lrs,
      query=marsha_common.queries.downloads,
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
  gridPos={ x: 9.6, y: 0, w: 14.4, h: 12 }
)
