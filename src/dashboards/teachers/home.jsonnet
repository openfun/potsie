// Video course dashboard

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local dashlist = grafana.dashlist;
local common = import '../common.libsonnet';


dashboard.new(
  'Home',
  tags=[common.tags.teacher],
  editable=false,
  time_from='now-90d',
  uid=common.uids.teachers_home,
)
.addPanel(
  dashlist.new(
    title='My dashboards',
    starred=true,
    search=true,
    recent=false,
    tags=[common.tags.xapi, common.tags.teacher],
  ),
  gridPos={ x: 0, y: 0, w: 12, h: 24 }
)
