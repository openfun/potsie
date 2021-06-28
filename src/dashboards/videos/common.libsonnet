local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;

{
  constants: {
    lrs: 'lrs',
    verb_id_completed: 'http://adlnet.gov/expapi/verbs/completed',
    verb_id_played: 'https://w3id.org/xapi/video/verbs/played',
  },
  fields: {
    actor_account_name: 'actor.account.name.keyword',
    context_extensions_completion_threshold: 'context.extensions.https://w3id.org/xapi/video/extensions/completion-threshold',
    course: 'object.definition.extensions.http://adlnet.gov/expapi/activities/course.keyword',
    result_extensions_length: 'result.extensions.https://w3id.org/xapi/video/extensions/length',
    result_extensions_time: 'result.extensions.https://w3id.org/xapi/video/extensions/time',
    school: 'object.definition.extensions.https://w3id.org/xapi/acrossx/extensions/school.keyword',
    session: 'object.definition.extensions.http://adlnet.gov/expapi/activities/module.keyword',
    video_id: 'object.id.keyword',
  },
  utils: {
    double_escape_string(x):: std.strReplace(std.strReplace(x, ':', '\\\\:'), '/', '\\\\/'),
    single_escape_string(x):: std.strReplace(std.strReplace(x, ':', '\\:'), '/', '\\/'),
  },
  objects: {
    count_metric: { id: '1', type: 'count' },
    date_histogram(interval='auto', min_doc_count='1'):: {
      id: 'date',
      field: 'timestamp',
      type: 'date_histogram',
      settings: {
        interval: interval,
        min_doc_count: min_doc_count,
        trimEdges: '0',
      },
    },
  },
  queries: {
    school_course_session: '%(school)s:$SCHOOL AND %(course)s:$COURSE AND %(session)s:$SESSION' % {
      school: $.utils.single_escape_string($.fields.school),
      course: $.utils.single_escape_string($.fields.course),
      session: $.utils.single_escape_string($.fields.session),
    },
  },
  templates: {
    course: template.new(
      name='COURSE',
      current='all',
      label='Course',
      datasource=$.constants.lrs,
      query='{"find": "terms", "field": "%(course)s", "query": "%(school)s:$SCHOOL"}' % {
        course: $.fields.course,
        school: $.utils.double_escape_string($.fields.school),
      },
      refresh='time'
    ),
    school: template.new(
      name='SCHOOL',
      current='all',
      label='School',
      datasource=$.constants.lrs,
      query='{"find": "terms", "field": "%(school)s"}' % { school: $.fields.school },
      refresh='time'
    ),
    session: template.new(
      name='SESSION',
      current='all',
      label='Session',
      datasource=$.constants.lrs,
      query='{"find": "terms", "field": "%(session)s", "query": "%(course)s:$COURSE"}' % {
        session: $.fields.session,
        course: $.utils.double_escape_string($.fields.course),
      },
      refresh='time'
    ),
    statements_interval: template.custom(
      name='STATEMENTS_INTERVAL',
      current='7d',
      label='Statements interval',
      query='1d,7d,14d,21d,28d',
      refresh='time'
    ),
    view_count_threshold: template.custom(
      name='VIEW_COUNT_THRESHOLD',
      current='30',
      label='View count threshold',
      query='0,10,20,30,40,50,60',
      refresh='time'
    ),
  },
}
