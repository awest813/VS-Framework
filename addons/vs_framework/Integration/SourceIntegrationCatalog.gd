## SourceIntegrationCatalog — ordered list of approved external reference profiles.
extends Resource
class_name SourceIntegrationCatalog

## Sources are stored in review order; blocked sources may be present to document explicit exclusions.
@export var sources : Array[SourceIntegrationProfile] = []


func get_source(source_name : String) -> SourceIntegrationProfile:
	for source in sources:
		if source and source.source_name == source_name:
			return source
	return null


func get_allowed_sources() -> Array[SourceIntegrationProfile]:
	var allowed : Array[SourceIntegrationProfile] = []
	for source in sources:
		if source and not source.is_blocked():
			allowed.append(source)
	return allowed


func get_blocked_sources() -> Array[SourceIntegrationProfile]:
	var blocked : Array[SourceIntegrationProfile] = []
	for source in sources:
		if source and source.is_blocked():
			blocked.append(source)
	return blocked


func get_sources_for_module(module_name : String, include_blocked : bool = false) -> Array[SourceIntegrationProfile]:
	var matches : Array[SourceIntegrationProfile] = []
	for source in sources:
		if not source:
			continue
		if source.is_blocked() and not include_blocked:
			continue
		if source.targets_module(module_name):
			matches.append(source)
	return matches


func get_code_reuse_candidates() -> Array[SourceIntegrationProfile]:
	var candidates : Array[SourceIntegrationProfile] = []
	for source in sources:
		if source and source.can_reuse_code():
			candidates.append(source)
	return candidates
