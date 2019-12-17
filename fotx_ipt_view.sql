CREATE or REPLACE VIEW ipt AS SELECT
	co.catalog_number as catalogNumber,
	/* Missing Previous Catalog Number*/
	/*Should below be the co.id?*/
	co.collecting_event_id as occurenceID,
	coalesce(co.verbatim_specimen_comments,'') as occurenceRemarks,
	dt.name as basisOfRecord,
	coalesce(co.verbatim_preparation) as preparations,

	/* Recorded By (Collectors) */
	s.name as recordedBy,

 	coalesce(cast(ce.start_date as text),'') as eventDate,
 	coalesce(cast(extract(year from ce.start_date) as text),'') as year,
 	coalesce(cast(extract(month from ce.start_date) as text),'') as month,
 	coalesce(cast(extract(day from ce.start_date) as text),'') as day,
 	coalesce(co.field_number,'') as fieldNumber,
 	coalesce(co.verbatim_collecting_event_comments,'') as eventRemarks,
 	/*j.name as higherGeography,*/
 	concat_ws('|',continent.name,country.name,state.name,j.name) as higherGeography,
 	'Ichthyology Collection'  AS collectionCode,
  	'TNHC'  AS institutionCode,
  	/*CASE
  			when continent.name = 'Earth' then
  				country.name as continent
  				state.name as country
  				county.name as state
  			when country.name = 'Earth' then
  				state.name as continent
  				county.name as country
  			when state.name = 'Earth' then
  				county.name as continent
  	END;*/

  	(CASE
  			when continent.name = 'Earth' then country.name
  			when country.name = 'Earth' then state.name
  			when state.name = 'Earth' then j.name
  			else continent.name
  	END) as continent,
  	(CASE
  			when country.name = 'Earth' then state.name
  			when state.name = 'Earth' then j.name
  			else country.name	
  	END) as country,
  	(CASE
  			when state.name = 'Earth' then j.name	
  			else state.name
  	END) as state,
  	(CASE
  			when j.name = 'Earth' then ''
  			else j.name	
  	END) as county

	FROM collection_object as co
	left join collecting_event as ce on co.collecting_event_id = ce.id
	left join collector as cc on ce.id = cc.collecting_event_id
	left join determination as de on co.id = de.collection_object_id
	left join agent as a on cc.agent_id = a.id
	/*Create Collector String*/
	left join (SELECT collecting_event.id as cid, 
		string_agg(concat_ws(' ',agent.first_name,agent.last_name),'|') as name 
		from collecting_event 
		left join collector on collector.collecting_event_id = collecting_event.id
		left join agent on agent.id = collector.agent_id
		group by cid) as s on s.cid = ce.id
	left join data_type as dt on dt.id = co.data_type_id
	left join locality as l on l.id = ce.locality_id
	left join jurisdiction as j on j.id = l.jurisdiction_id
	left join jurisdiction_type as jt on jt.id = j.jurisdiction_type_id
	left join jurisdiction as state on state.id = j.parent_id
	left join jurisdiction as country on country.id = state.parent_id
	left join jurisdiction as continent on continent.id = country.parent_id



