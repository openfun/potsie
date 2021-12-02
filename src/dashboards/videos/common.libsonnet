// Video commons

local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;
local common = import '../common.libsonnet';

{
  datasources: {
    lrs: 'lrs',
  },
  fields: {
    context_extensions_completion_threshold: 'context.extensions.https://w3id.org/xapi/video/extensions/completion-threshold',
    result_extensions_length: 'result.extensions.https://w3id.org/xapi/video/extensions/length',
    result_extensions_time: 'result.extensions.https://w3id.org/xapi/video/extensions/time',
    verb_display_en_us: 'verb.display.en-US.keyword',
    video_id: 'object.id.keyword',
  },
  queries: {
    school_course_session: '%(school)s:$SCHOOL AND %(course)s:$COURSE AND %(session)s:$SESSION' % {
      course: common.utils.single_escape_string(common.fields.course),
      school: common.utils.single_escape_string(common.fields.school),
      session: common.utils.single_escape_string(common.fields.session),
    },
    course_key: 'context.contextActivities.parent.id.keyword',
    video_id: 'object.id.keyword:$VIDEO',
  },
  templates: {
    course: template.new(
      name='COURSE',
      current='all',
      label='Course',
      datasource=$.datasources.lrs,
      query='{"find": "terms", "field": "%(course)s", "query": "%(school)s:$SCHOOL"}' % {
        course: common.fields.course,
        school: common.utils.double_escape_string(common.fields.school),
      },
      refresh='time'
    ),
    course_key: template.new(
      name='COURSE KEY',
      current='all',
      label='Courses Key',
      datasource=$.datasources.lrs,
      query='{"find": "terms", "field": "%(course_key)s"}' % { course_key: common.fields.course_key },
      refresh='time'
    ),
    event_group_interval: template.custom(
      name='EVENT_GROUP_INTERVAL',
      current='30',
      label='Event group interval',
      query='1,10,20,30,60,120,180,300,600',
      refresh='time'
    ),
    school: template.new(
      name='SCHOOL',
      current='all',
      label='School',
      datasource=$.datasources.lrs,
      query='{"find": "terms", "field": "%(school)s"}' % { school: common.fields.school },
      refresh='time'
    ),
    session: template.new(
      name='SESSION',
      current='all',
      label='Session',
      datasource=$.datasources.lrs,
      query='{"find": "terms", "field": "%(session)s", "query": "%(course)s:$COURSE"}' % {
        session: common.fields.session,
        course: common.utils.double_escape_string(common.fields.course),
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
    video: template.new(
      name='VIDEO',
      current='all',
      label='Video',
      datasource=$.datasources.lrs,
      query='{"find": "terms", "field": "%(video_id)s", "query": "%(course)s:$COURSE AND %(session)s:$SESSION"}' % {
        video_id: $.fields.video_id,
        course: common.utils.double_escape_string(common.fields.course),
        session: common.utils.double_escape_string(common.fields.session),
      },
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
