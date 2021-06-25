local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local template = grafana.template;


// Constants
local lrs = 'lrs';
local actor_account_name_field = 'actor.account.name.keyword';
local course_field = 'object.definition.extensions.http://adlnet.gov/expapi/activities/course.keyword';
local result_extensions_time_field = 'result.extensions.https://w3id.org/xapi/video/extensions/time';
local school_field = 'object.definition.extensions.https://w3id.org/xapi/acrossx/extensions/school.keyword';
local session_field = 'object.definition.extensions.http://adlnet.gov/expapi/activities/module.keyword';
local video_id_field = 'object.id.keyword';
local verb_id_played_value = 'https://w3id.org/xapi/video/verbs/played';

// Queries
local video_id_query = 'object.id.keyword:$VIDEO';


// Utils
local double_escape_string(x) = std.strReplace(std.strReplace(x, ':', '\\\\:'), '/', '\\\\/');
local single_escape_string(x) = std.strReplace(std.strReplace(x, ':', '\\:'), '/', '\\/');


// Dashboard
dashboard.new(
  'Details',
  tags=['xAPI', 'video', 'teacher'],
  editable=false
)
.addTemplate(
  template.new(
    name='SCHOOL',
    current='all',
    label='School',
    datasource=lrs,
    query='{"find": "terms", "field": "%(school)s"}' % {
      school: school_field,
    },
    refresh='time'
  )
)
.addTemplate(
  template.new(
    name='COURSE',
    current='all',
    label='Course',
    datasource=lrs,
    query='{"find": "terms", "field": "%(course)s", "query": "%(school)s:$SCHOOL"}' % {
      course: course_field,
      school: double_escape_string(school_field),
    },
    refresh='time'
  )
)
.addTemplate(
  template.new(
    name='SESSION',
    current='all',
    label='Session',
    datasource=lrs,
    query='{"find": "terms", "field": "%(session)s", "query": "%(course)s:$COURSE"}' % {
      session: session_field,
      course: double_escape_string(course_field),
    },
    refresh='time'
  )
)
.addTemplate(
  template.new(
    name='VIDEO',
    current='all',
    label='Video',
    datasource=lrs,
    query='{"find": "terms", "field": "%(video_id)s", "query": "%(course)s:$COURSE AND %(session)s:$SESSION"}' % {
      video_id: video_id_field,
      course: double_escape_string(course_field),
      session: double_escape_string(session_field),
    },
    refresh='time'
  )
)
.addTemplate(
  template.custom(
    name='VIEW_COUNT_THRESHOLD',
    current='30',
    label='View count threshold',
    query='0,10,20,30,40,50,60',
    refresh='time'
  )
)
.addPanel(
  graphPanel.new(
    title='Verbs',
    datasource=lrs,
    bars=true,
    lines=false,
  ).addTarget(
    elasticsearch.target(
      datasource=lrs,
      query=video_id_query,
      metrics=[
        {
          id: '1',
          type: 'count',
        },
      ],
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
          field: 'timestamp',
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
  gridPos={ x: 0, y: 0, w: 12, h: 9 }
)
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
    datasource=lrs,
    reducerFunction='sum',
    unit='none'
  ).addTarget(
    elasticsearch.target(
      datasource=lrs,
      query='%(video_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO $VIEW_COUNT_THRESHOLD]' % {
        video_query: video_id_query,
        verb_played: verb_id_played_value,
        time: single_escape_string(result_extensions_time_field),
      },
      metrics=[
        {
          id: '1',
          type: 'count',
        },
      ],
      bucketAggs=[
        {
          id: 'date',
          field: 'timestamp',
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
  gridPos={ x: 12, y: 0, w: 6, h: 9 }
)
.addPanel(
  graphPanel.new(
    title='Daily views',
    description=|||
      A view is counted when the user has clicked the play button in the interface
      in the first ${VIEW_COUNT_THRESHOLD} seconds of the video.
    |||,
    datasource=lrs,
  ).addTarget(
    elasticsearch.target(
      datasource=lrs,
      query='%(video_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO $VIEW_COUNT_THRESHOLD]' % {
        video_query: video_id_query,
        verb_played: verb_id_played_value,
        time: single_escape_string(result_extensions_time_field),
      },
      metrics=[
        {
          id: '1',
          type: 'count',
        },
      ],
      bucketAggs=[
        {
          id: 'date',
          field: 'timestamp',
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
  gridPos={ x: 12, y: 9, w: 12, h: 9 }
)
.addPanel(
  statPanel.new(
    title='Unique views',
    description=|||
      Unique views are views aggregated by users: each user can generate
      at most one view in this metric.
    |||,
    datasource=lrs,
    graphMode='none',
    reducerFunction='sum',
    unit='none',
    fields='/^Unique Count$/'
  ).addTarget(
    elasticsearch.target(
      datasource=lrs,
      query='%(video_query)s AND verb.id:"%(verb_played)s"' % {
        video_query: video_id_query,
        verb_played: verb_id_played_value,
      },
      metrics=[
        {
          id: '1',
          type: 'cardinality',
          field: actor_account_name_field,
        },
      ],
      bucketAggs=[
        {
          id: 'name',
          field: actor_account_name_field,
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
  gridPos={ x: 18, y: 0, w: 6, h: 9 }
)
