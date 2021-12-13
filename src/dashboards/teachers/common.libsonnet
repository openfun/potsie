// Teacher commons

local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;
local common = import '../common.libsonnet';

{
  fields: {
    context_extensions_completion_threshold: 'context.extensions.https://w3id.org/xapi/video/extensions/completion-threshold',
    result_extensions_length: 'result.extensions.https://w3id.org/xapi/video/extensions/length',
    result_extensions_time: 'result.extensions.https://w3id.org/xapi/video/extensions/time',
    verb_display_en_us: 'verb.display.en-US.keyword',
  },
  queries: {
    course_key: 'context.contextActivities.parent.id.keyword:${EDX_COURSE_KEY:doublequote}',
    course_query: '%(course_key)s OR (%(school_course_session)s)' % {
      course_key: $.queries.course_key,
      school_course_session: $.queries.school_course_session,
    },
    edx_course_key: 'SELECT `key` FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    school_course_session: '%(school)s:${SCHOOL:doublequote} AND %(course)s:${COURSE:doublequote} AND %(session)s:${SESSION:doublequote}' % {
      course: common.utils.single_escape_string(common.fields.course),
      school: common.utils.single_escape_string(common.fields.school),
      session: common.utils.single_escape_string(common.fields.session),
    },
    video_id: 'object.id.keyword:${VIDEO:doublequote}',
  },
  templates: {
    edx_course_key: template.new(
      name='EDX_COURSE_KEY',
      current='all',
      label='Edx Course Key',
      datasource=common.datasources.edx_app,
      query='SELECT DISTINCT %(course_id)s FROM `student_courseaccessrole` WHERE (%(user_id)s = (%(query_user_id)s) AND %(role)s IN ("staff", "instructor"))' % {
        course_id: '`student_courseaccessrole`.`course_id`',
        user_id: '`student_courseaccessrole`.`user_id`',
        query_user_id: 'SELECT id from auth_user WHERE email=${__user.email:sqlstring}',
        role: '`student_courseaccessrole`.`role`',
      },
      refresh='time',
      sort=1,
    ),
    school: template.new(
      name='SCHOOL',
      current='all',
      label='School',
      datasource=common.datasources.edx_app,
      query=$.queries.edx_course_key,
      regex='/course-v1:(.*)\\+\\d+\\+.*/',
      hide='variable',
      refresh='time'
    ),
    course: template.new(
      name='COURSE',
      current='all',
      label='Course',
      datasource=common.datasources.edx_app,
      query=$.queries.edx_course_key,
      regex='/course-v1:.*\\+(\\d+)\\+.*/',
      hide='variable',
      refresh='time'
    ),
    session: template.new(
      name='SESSION',
      current='all',
      label='Session',
      datasource=common.datasources.edx_app,
      query=$.queries.edx_course_key,
      regex='/course-v1:.*\\+\\d+\\+(.*)/',
      hide='variable',
      refresh='time'
    ),
    event_group_interval: template.custom(
      name='EVENT_GROUP_INTERVAL',
      current='30',
      label='Event group interval',
      query='1,10,20,30,60,120,180,300,600',
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
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_id)s", "query": "%(course_key)s OR (%(school_course_session)s)"}' % {
        video_id: common.fields.video_id,
        course_key: $.queries.course_key,
        school_course_session: std.strReplace($.queries.school_course_session, '\\', '\\\\'),
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
