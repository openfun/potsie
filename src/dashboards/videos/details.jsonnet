local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local elasticsearch = grafana.elasticsearch;
local graphPanel = grafana.graphPanel;
local template = grafana.template;


// Constants
local lrs = 'lrs';
local course_field = 'object.definition.extensions.http://adlnet.gov/expapi/activities/course.keyword';
local school_field = 'object.definition.extensions.https://w3id.org/xapi/acrossx/extensions/school.keyword';
local session_field = 'object.definition.extensions.http://adlnet.gov/expapi/activities/module.keyword';
local video_id_field = 'object.id.keyword';


// Utils
local double_escape_string(x) = std.strReplace(std.strReplace(x, ':', '\\\\:'), '/', '\\\\/');


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
.addPanel(
  graphPanel.new(
    title='Verbs',
    datasource=lrs,
    bars=true,
    lines=false,
  ).addTarget(
    elasticsearch.target(
      datasource=lrs,
      query='object.id.keyword:$VIDEO',
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
