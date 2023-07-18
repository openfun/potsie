// General commons

{
  datasources: {
    lrs: 'lrs',
    edx_app: 'edx_app',
    marsha: 'marsha',
  },
  fields: {
    actor_account_name: 'actor.account.name.keyword',
    video_id: 'object.id',
    subtitle_enabled: 'context.extensions.https://w3id.org/xapi/video/extensions/cc-subtitle-enabled',
    full_screen: 'context.extensions.https://w3id.org/xapi/video/extensions/full-screen',
    speed: 'context.extensions.https://w3id.org/xapi/video/extensions/speed.keyword',
    subtitle_language: 'context.extensions.https://w3id.org/xapi/video/extensions/cc-subtitle-lang.keyword',
    quality: 'context.extensions.https://w3id.org/xapi/video/extensions/quality',
    volume: 'context.extensions.https://w3id.org/xapi/video/extensions/volume',
  },
  metrics: {
    count: { id: '1', type: 'count' },
    cardinality(field):: {
      id: '1',
      type: 'cardinality',
      field: field,
    },
    max(field):: {
      id: '1',
      type: 'max',
      field: field,
    },
  },
  objects: {
    date_histogram(interval='auto', min_doc_count='1'):: {
      id: 'date',
      field: '@timestamp',
      type: 'date_histogram',
      settings: {
        interval: interval,
        min_doc_count: min_doc_count,
        trimEdges: '0',
      },
    },
  },
  tags: {
    staff: 'staff',
    teacher: 'teacher',
    video: 'video',
    xapi: 'xAPI',
  },
  utils: {
    double_escape_string(x):: std.strReplace(std.strReplace(std.strReplace(x, ':', '\\\\:'), '/', '\\\\/'), '-', '\\\\-'),
    single_escape_string(x):: std.strReplace(std.strReplace(std.strReplace(x, ':', '\\:'), '/', '\\/'), '-', '\\-'),
  },
  uids: {
    course_video_overview: '855bbd9f-09eb-42ac-aa5f-d0a2c6f8ee34',
    course_video_details: 'c6cc2218-4fea-4b4c-a622-245f3aa22893',
    teachers_home: '451f4aa3-d094-429e-ad87-4b6c809ffa35',
  },
  verb_ids: {
    completed: 'http://adlnet.gov/expapi/verbs/completed',
    initialized: 'http://adlnet.gov/expapi/verbs/initialized',
    played: 'https://w3id.org/xapi/video/verbs/played',
    downloaded: 'http://id.tincanapi.com/verb/downloaded',
    interacted: 'http://adlnet.gov/expapi/verbs/interacted',
  },
}
