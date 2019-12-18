CREATE or REPLACE VIEW ipt AS SELECT
	distinct(co.catalog_number) as catalogNumber,
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
  	(CASE
        when state.name = 'Earth' then j.name
  			when country.name = 'Earth' then state.name
        when continent.name = 'Earth' then country.name
  			else continent.name
  	END) as continent,
  	(CASE
        when country.name = 'Earth' then j.name
  			when continent.name = 'Earth' then state.name
  			else country.name	
  	END) as country,
  	(CASE
  			when country.name is null then ''	
        when continent.name is null then ''
  			else state.name
  	END) as state,
  	(CASE
        when state.name is null then ''
        when country.name is null then ''
        when continent.name is null then ''
  			else j.name	
  	END) as county,

    l.name as locality,
    coalesce(cast(l.longitude as text),'') as decimalLongitude,
    coalesce(cast(l.latitude as text),'') as decimalLatitude,
    round(l.maximum_uncertainty_estimate) as coordinateUncertaintyInMeters,
    l.remarks as georeferenceRemarks,
    dd.name as identifiedBy,
    /* Using Date Last Modified as Default */
    de.last_modified as dateIdentified,
    coalesce(de.identification_comments,'') as identificationRemarks,
    
    /************Type Status? ********************/

    coalesce(t.full_name,'') as scientificName,
    coalesce(tr.name,'') as taxon_rank,

    (CASE
      when kingdom.full_name = 'Life' then phylum.full_name
      when phylum.full_name = 'Life' then class.full_name
      when class.full_name = 'Life'  then ordert.full_name
      when ordert.full_name ='Life' then family.full_name
      when family.full_name = 'Life' then genus.full_name
      when genus.full_name = 'Life' then species.full_name
      when species.full_name = 'Life' then t.full_name
      else kingdom.full_name
    END) as kingdom,
    (CASE
      when kingdom.full_name = 'Life' then class.full_name
      when phylum.full_name = 'Life'  then ordert.full_name
      when class.full_name ='Life' then family.full_name
      when ordert.full_name = 'Life' then genus.full_name
      when family.full_name = 'Life' then species.full_name
      when genus.full_name = 'Life' then t.full_name
      when species.full_name = 'Life' then ''
      else phylum.full_name
    END) as phylum,
    (CASE
      when kingdom.full_name = 'Life' then ordert.full_name
      when phylum.full_name = 'Life'  then family.full_name
      when class.full_name ='Life' then genus.full_name
      when ordert.full_name = 'Life' then species.full_name
      when family.full_name = 'Life' then t.full_name
      when genus.full_name = 'Life' then ''
      when species.full_name = 'Life' then ''
      else class.full_name
    END) as class,
    (CASE
      when kingdom.full_name = 'Life' then family.full_name
      when phylum.full_name = 'Life'  then genus.full_name
      when class.full_name ='Life' then species.full_name
      when ordert.full_name = 'Life' then t.full_name
      when family.full_name = 'Life' then ''
      when genus.full_name = 'Life' then ''
      when species.full_name = 'Life' then ''
      else ordert.full_name
    END) as order,
    (CASE
      when kingdom.full_name = 'Life' then genus.full_name
      when phylum.full_name = 'Life'  then species.full_name
      when class.full_name ='Life' then t.full_name
      when ordert.full_name = 'Life' then ''
      when family.full_name = 'Life' then ''
      when genus.full_name = 'Life' then ''
      when species.full_name = 'Life' then ''
      else family.full_name
    END) as family,
    (CASE
      when kingdom.full_name = 'Life' then species.full_name
      when phylum.full_name = 'Life'  then t.full_name
      when class.full_name ='Life' then ''
      when ordert.full_name = 'Life' then ''
      when family.full_name = 'Life' then ''
      when genus.full_name = 'Life' then ''
      when species.full_name = 'Life' then ''
      else genus.full_name
    END) as genus,
    (CASE
      when kingdom.full_name = 'Life' then split_part(t.full_name,' ',2)
      when phylum.full_name = 'Life'  then ''
      when class.full_name ='Life' then ''
      when ordert.full_name = 'Life' then ''
      when family.full_name = 'Life' then ''
      when genus.full_name = 'Life' then ''
      when species.full_name = 'Life' then ''
      else species.full_name
    END) as specificEpithet,

    /*Don't know if there are any sub-species determinations in Taxonomy?*/
    (CASE
      when kingdom.full_name = 'Life' then ''
      when phylum.full_name = 'Life'  then ''
      when class.full_name ='Life' then ''
      when ordert.full_name = 'Life' then ''
      when family.full_name = 'Life' then ''
      when genus.full_name = 'Life' then ''
      when species.full_name = 'Life' then ''
      else species.full_name
    END) as infraspecificEpithet

    /* Sequence Data & Media Attachments? */
    /* Couldn't figure out how this was formatted */


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
  /*Create Determiner String*/
  left join(SELECT collection_object.id as coid, string_agg(concat_ws('',agent.first_name,agent.last_name),'|') as name
    from collection_object
    left join determination on determination.collection_object_id = collection_object.id
    left join agent on agent.id = determination.determiner_id
    group by coid) as dd on dd.coid = co.id
  /*Subspecies*/
  left join taxon as t on t.id = de.taxon_id
  left join taxon_rank as tr on tr.id = t.taxon_rank_id
  left join taxon as species on species.id = t.parent_id
  left join taxon as genus on genus.id = species.parent_id
  left join taxon as family on family.id = genus.parent_id
  left join taxon as ordert on ordert.id = family.parent_id
  left join taxon as class on class.id = ordert.parent_id
  left join taxon as phylum on phylum.id = class.parent_id
  left join taxon as kingdom on kingdom.id = phylum.parent_id
  /* Order By */
  order by co.catalog_number