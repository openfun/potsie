// General commons

{
  datasources: {
    lrs: 'lrs',
    edx_app: 'edx_app',
    marsha: 'marsha',
  },
  fields: {
    actor: {
      account: {
        name: 'actor.account.name.keyword',
      },
    },
    object: {
      id: 'object.id',
    },
    verb: {
      display: {
        en_US: 'verb.display.en-US.keyword',
      },
      id: {
        completed: 'http://adlnet.gov/expapi/verbs/completed',
        initialized: 'http://adlnet.gov/expapi/verbs/initialized',
        played: 'https://w3id.org/xapi/video/verbs/played',
        downloaded: 'http://id.tincanapi.com/verb/downloaded',
        interacted: 'http://adlnet.gov/expapi/verbs/interacted',
      },
    },
    context: {
      contextActivities: {
        parent: {
          id: 'context.contextActivities.parent.id',
        },
      },
      extensions: {
        completion_threshold: 'context.extensions.https://w3id.org/xapi/video/extensions/completion-threshold',
        subtitle_enabled: 'context.extensions.https://w3id.org/xapi/video/extensions/cc-subtitle-enabled',
        full_screen: 'context.extensions.https://w3id.org/xapi/video/extensions/full-screen',
        length: 'context.extensions.https://w3id.org/xapi/video/extensions/length',
        speed: 'context.extensions.https://w3id.org/xapi/video/extensions/speed.keyword',
        subtitle_language: 'context.extensions.https://w3id.org/xapi/video/extensions/cc-subtitle-lang.keyword',
        quality: 'context.extensions.https://w3id.org/xapi/video/extensions/quality',
        volume: 'context.extensions.https://w3id.org/xapi/video/extensions/volume',
      },
    },
    result: {
      extensions: {
        length: 'result.extensions.https://w3id.org/xapi/video/extensions/length',
        time: 'result.extensions.https://w3id.org/xapi/video/extensions/time',
      },
    },
  },
  tags: {
    staff: 'staff',
    teacher: 'teacher',
    video: 'video',
    xapi: 'xAPI',
  },
  uids: {
    course_video_overview: '855bbd9f-09eb-42ac-aa5f-d0a2c6f8ee34',
    course_video_details: 'c6cc2218-4fea-4b4c-a622-245f3aa22893',
    teachers_home: '451f4aa3-d094-429e-ad87-4b6c809ffa35',
  },
}
