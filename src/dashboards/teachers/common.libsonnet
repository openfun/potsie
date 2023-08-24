// Teacher commons

local common = import '../common.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;
local template = grafana.template;
local utils = import '../utils.libsonnet';

{
  constants:
    {
      view_count_threshold: '30',
      event_group_interval: '1',
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
    complete_views: 'verb.id:"%(verb_completed)s"' % {
      verb_completed: common.fields.verb.id.completed,
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
    downloads: 'verb.id:"%(verb_downloaded)s"' % {
      verb_downloaded: common.fields.verb.id.downloaded,
    },
    edx_course_key: 'SELECT `key` FROM courses_course WHERE `key`="${EDX_COURSE_KEY}"',
    interactions: 'verb.id:"%(verb_interacted)s"' % {
      verb_interacted: common.fields.verb.id.interacted,
    },
    video_iri: 'object.id:${VIDEO_IRI:doublequote}',
    video_title: 'SELECT title from video where id=${VIDEO_ID:sqlstring}',
    views: 'verb.id:"%(verb_played)s" AND %(time)s:[0 TO %(view_count_threshold)s]' % {
      verb_played: common.fields.verb.id.played,
      time: utils.functions.single_escape_string(common.fields.result.extensions.time),
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
    course_title: template.new(
      name='COURSE_TITLE',
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
    video_iri: template.new(
      name='VIDEO_IRI',
      label='Video',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_iri)s", "query": "%(course_key)s"}' % {
        video_iri: common.fields.object.id,
        course_key: $.queries.course_key,
      },
      refresh='time'
    ),
    video_id: template.new(
      name='VIDEO_ID',
      label='Video',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_iri)s", "query": "object.id:${VIDEO_IRI}"}' % {
        video_iri: common.fields.object.id,
      },
      regex='/uuid\\:\\/\\/(?<value>.*)/',
      hide='variable',
      refresh='time'
    ),
    video_title: template.new(
      name='VIDEO_TITLE',
      current='all',
      label='Title',
      datasource=common.datasources.marsha,
      query=$.queries.video_title,
      hide='variable',
      refresh='time'
    ),
    course_videos_ids: template.new(
      name='COURSE_VIDEOS_IDS',
      current='all',
      hide='variable',
      label='Course videos identifiers',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_iri)s", "query": "%(course_key)s"}' % {
        video_iri: common.fields.object.id,
        course_key: $.queries.course_key,
      },
      multi='true',
      includeAll='true',
      regex='/uuid\\:\\/\\/(?<value>.*)/',
      refresh='time',
    ),
    course_videos_iris: template.new(
      name='COURSE_VIDEOS_IDS_WITH_UUID',
      hide='variable',
      current='all',
      label='Video',
      datasource=common.datasources.lrs,
      query='{"find": "terms", "field": "%(video_iri)s", "query": "%(course_key)s"}' % {
        video_iri: common.fields.object.id,
        course_key: $.queries.course_key,
      },
      multi='true',
      includeAll='true',
      refresh='time',
    ),
  },
}
