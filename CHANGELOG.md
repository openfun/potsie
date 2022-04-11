# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Fix demo date courses according to the current date

## [0.4.3] - 2022-04-07

### Fixed

- Course videos metrics were improperly collected

## [0.4.2] - 2022-04-06

### Fixed

- Restore post-deploy hook folder uid checking

## [0.4.1] - 2022-04-06

### Fixed

- Hooks should be included in releases along with compiled dashboards and
  plugins
- Make post-deploy hooks more reliable

## [0.4.0] - 2022-04-06

### Added

- Implement post-deployment hooks
- Improve dashboards layout on Teachers Video Dashboard
- Videos views table on Teachers Course Video Overview Dashboard linked
with corresponding Teachers Course Video Details Dashboard
- Video interaction activities details on Teachers Course Video Details
  Dashboard
- Average views and complete views numbers in Teachers Course Video Overview
  Dashboard

## [0.3.0] - 2022-01-27

### Added

- Download panel on Teachers Course Video Overview dashboard
- Links between Teachers folder dashboards
- Metadata panels for Teachers dashboard
- Teachers dashboards for video activity

### Changed

- Upgrade `jsonnet` to 0.18.0
- Upgrade `Grafana` to 8.3.3

### Fixed

- `edx_mysql` datasource password configuration should stand in the
  `secureJsonData` field

### Removed

- Statements interval, view count threshold and event group interval variables
- Video dashboards

## [0.2.0] - 2021-12-06

### Added

- Stacked-barchart plugin subproject
- Video course and statements Dashboards
- Platform user in General Dashboard
- `mysql` datasource provisioning from edx app
- Video details dashboard new panel: video events distribution along the video
  timeline
- Course video events distribution panel in details Dashboard
- Completion threshold metrics in details Dashboard
- Complete views, unique complete views panels in details Dashboard
- Views, unique views and daily views panels in details Dashboard

### Changed

- Upgrade `Grafana` to 8.0.3
- Move the elasticsearch data source to a datastream

## [0.1.0] - 2021-06-22

### Added

- Video details Dashboard

[unreleased]: https://github.com/openfun/potsie/compare/v0.4.3...main
[0.4.3]: https://github.com/openfun/potsie/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/openfun/potsie/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/openfun/potsie/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/openfun/potsie/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/openfun/potsie/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/openfun/potsie/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/openfun/potsie/compare/1172535...v0.1.0
