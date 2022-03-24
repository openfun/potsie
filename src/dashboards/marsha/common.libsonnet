// Marsha commons

local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;
local common = import '../common.libsonnet';

{
  constants:
    {
      view_count_threshold: '30',
    },
  fields: {
    result_extensions_time: 'result.extensions.https://w3id.org/xapi/video/extensions/time',
  },
  queries: {
    complete_views: '%(video_query)s AND verb.id:"%(verb_completed)s"' % {
      video_query: $.queries.video_id,
      verb_completed: common.verb_ids.completed,
    },
    course_key: 'context.contextActivities.parent.id.keyword:${EDX_COURSE_KEY:doublequote}',
    course_query: '%(course_key)s OR (%(school_course_session)s)' % {
      course_key: $.queries.course_key,
      school_course_session: $.queries.school_course_session,
    },
    downloads: '%(video_query)s AND verb.id:"%(verb_downloaded)s"' % {
      video_query: $.queries.video_id,
      verb_downloaded: common.verb_ids.downloaded,
    },
    edx_course_key: 'SELECT `key` FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    school_course_session: '%(school)s:${SCHOOL:doublequote} AND %(course)s:${COURSE:doublequote} AND %(session)s:${SESSION:doublequote}' % {
      course: common.utils.single_escape_string(common.fields.course),
      school: common.utils.single_escape_string(common.fields.school),
      session: common.utils.single_escape_string(common.fields.session),
    },
    video_id: 'object.id.keyword:${VIDEO:doublequote}',
    views: '%(video_query)s AND verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
      video_query: $.queries.video_id,
      verb_played: common.verb_ids.played,
      time: common.utils.single_escape_string($.fields.result_extensions_time),
      view_count_threshold: $.constants.view_count_threshold,
    },
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
  },
}