-- Object: mart_energiemanagement.DIM_RECHENZENTRUM_KNOTEN
-- Type  : VIEW


CREATE view [mart_energiemanagement].[DIM_RECHENZENTRUM_KNOTEN] as


	with ebenen as (
		select
			e0.sysid id_ebene0
			,e1.sysid id_ebene1
			,e2.sysid id_ebene2
			,e3.sysid id_ebene3
		from
			(select * from raw.idoit_relationships where id_ebene = 3) e3
		left join
			(select * from raw.idoit_relationships where id_ebene = 2) e2 on e3.id_parent = e2.id
		left join
			(select * from raw.idoit_relationships where id_ebene = 1) e1 on e2.id_parent = e1.id
		left join
			(select * from raw.idoit_relationships where id_ebene = 0) e0 on e1.id_parent = cast(replace(e0.id,'.0','') as int)
	)
	select distinct
		e.id_ebene0,
		o0.title ebene0_name,
		o0.type_title ebene0_typ,
		o0.cmdb_status_title as ebene0_status,
		e.id_ebene1,
		o1.title ebene1_name,
		o1.type_title ebene1_typ,
		o1.cmdb_status_title as ebene1_status,
		e.id_ebene2,
		o2.title ebene2_name,
		o2.type_title ebene2_typ,
		o2.cmdb_status_title as ebene2_status,
		e.id_ebene3,
		o3.title ebene3_name,
		o3.type_title ebene3_typ,
		o3.cmdb_status_title as ebene3_status
	from 
		ebenen e
	join
		raw.idoit_objects o0 on e.id_ebene0 = o0.sysid --and o0.sysid = 'SYSID_1448492819'
	left join
		raw.idoit_objects o1 on e.id_ebene1 = o1.sysid 
	left join
		raw.idoit_objects o2 on e.id_ebene2 = o2.sysid
	left join
		raw.idoit_objects o3 on e.id_ebene3 = o3.sysid 


GO
