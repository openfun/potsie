local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local sql = grafana.sql;
local statPanel = grafana.statPanel;

local edx_app = 'edx_app';

dashboard.new(
  'General',
  editable=false,
  time_from='now-90d',
)
.addPanel(
  statPanel.new(
    title='Platform user',
    datasource=edx_app,
    reducerFunction='distinctCount',
    graphMode='none',
    unit='none',
    fields='/^username$/'
  ).addTarget(
    sql.target(
      datasource=edx_app,
      format='table',
      rawSql='SELECT DISTINCT username FROM auth_user',
    )
  ),
  gridPos={
    h: 9,
    w: 12,
    x: 0,
    y: 0,
  },
)
