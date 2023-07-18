// Teacher commons

local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;
local link = grafana.link;
local common = import '../common.libsonnet';

{
  constants:
    {
      view_count_threshold: '30',
      statements_interval: '1d',
      event_group_interval: '1',
    },
  fields: {
    context_extensions_completion_threshold: 'context.extensions.https://w3id.org/xapi/video/extensions/completion-threshold',
    result_extensions_length: 'result.extensions.https://w3id.org/xapi/video/extensions/length',
    result_extensions_time: 'result.extensions.https://w3id.org/xapi/video/extensions/time',
    verb_display_en_us: 'verb.display.en-US.keyword',
  },
  link: {
    teacher: link.dashboards(
      includeVars=true,
      keepTime=true,
      tags=[common.tags.teacher],
      title='Teacher dashboards',
      type='dashboards'
    ),
  },
  queries: {
    complete_views: '%(video_query)s AND verb.id:"%(verb_completed)s"' % {
      video_query: $.queries.video_id,
      verb_completed: common.verb_ids.completed,
    },
    course_key: 'context.contextActivities.parent.id:${EDX_COURSE_KEY:doublequote}',
    course_enrollments: 'SELECT DISTINCT COUNT(`user_id`) FROM `student_courseenrollment` WHERE (`is_active`=1 AND `course_id`="${EDX_COURSE_KEY}")',
    course_title: 'SELECT `title` FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    course_start_date: 'SELECT DATE_FORMAT(start_date, "%d/%m/%Y") FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    course_end_date: 'SELECT DATE_FORMAT(end_date, "%d/%m/%Y") FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    course_query: '%(course_key)s' % {
      course_key: $.queries.course_key,
    },
    course_videos: 'object.id:${COURSE_VIDEOS_IDS_WITH_UUID:lucene}',
    downloads: '%(video_query)s AND verb.id:"%(verb_downloaded)s"' % {
      video_query: $.queries.video_id,
      verb_downloaded: common.verb_ids.downloaded,
    },
    edx_course_key: 'SELECT `key` FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    video_interacted: '%(video_query)s AND verb.id:"%(verb_interacted)s"' % {
      video_query: $.queries.video_id,
      verb_interacted: common.verb_ids.interacted,
    },
    video_id: 'object.id:${VIDEO:doublequote}',
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
    title: template.new(
      name='TITLE',
      current='all',
      label='Title',
      datasource=common.datasources.edx_app,
      query=$.queries.course_title,
      hide='variable',
      refresh='time'
    ),
    start_date: template.new(
      name='START_DATE',
      current='all',
      label='Start Date',
      datasource=common.datasources.edx_app,
      query=$.queries.course_start_date,
      hide='variable',
      refresh='time'
    ),
    end_date: template.new(
      name='END_DATE',
      current='all',
      label='End Date',
      datasource=common.datasources.edx_app,
      query=$.queries.course_end_date,
      hide='variable',
      refresh='time'
    ),
    enrollments: template.new(
      name='ENROLLMENTS',
      current='all',
      label='Enrollment',
      datasource=common.datasources.edx_app,
      query=$.queries.course_enrollments,
      hide='variable',
      refresh='time'
    ),
    video: template.new(
      name='VIDEO',
      label='Video',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_id)s", "query": "%(course_key)s"}' % {
        video_id: common.fields.video_id,
        course_key: $.queries.course_key,
      },
      refresh='time'
    ),
    course_video_ids: template.new(
      name='COURSE_VIDEOS_IDS',
      current='all',
      hide='variable',
      label='Course videos identifiers',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_id)s", "query": "%(course_key)s"}' % {
        video_id: common.fields.video_id,
        course_key: $.queries.course_key,
      },
      multi='true',
      includeAll='true',
      regex='/uuid\\:\\/\\/(?<value>.*)/',
      refresh='time',
    ),
    course_video_ids_with_uuid: template.new(
      name='COURSE_VIDEOS_IDS_WITH_UUID',
      hide='variable',
      current='all',
      label='Video',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_id)s", "query": "%(course_key)s"}' % {
        video_id: common.fields.video_id,
        course_key: $.queries.course_key,
      },
      multi='true',
      includeAll='true',
      refresh='time',
    ),
  },
}
