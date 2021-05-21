local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;

dashboard.new(
    'Details',
    tags=['xAPI', 'video', 'teacher'],
    editable=false
)
.addTemplate(
    template.datasource(
        'PROMETHEUS_DS',
        'prometheus',
        'Prometheus',
        hide='label',
    )
)
