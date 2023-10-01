create schema Telengna_Revenue;
use Telengna_Revenue;

create table dim_date (
        Month date,
        Mmm varchar(10),
        Quarter varchar(3),
        Fiscal_year year);
        
create table dim_dist (
              dist_code varchar(10),
              district varchar (20)
              );
              
create table fact_stamps (
            dist_code varchar(10),
            Month date,
            Document_no bigint,
            Document_rev bigint,
            estamps_challans_cnt bigint,
            estamps_challans_rev bigint
            );
            
create table fact_transport (
               dist_code varchar(10),
               Month date,
               fuel_type_petrol int,
               fuel_type_diesel int,
               fuel_type_electric int,
               fuel_type_others int,
               vehicleClass_Motorcycles int,
               vehicleClass_Motorcars int,
               vehicleClass_Auto_rickshaws int,
               vehicleClass_Agriculture int,
               vehicleClass_Others int,
               seatCapacity_1_to_3 int,
               seatCapacity_4_to_6 int,
               seatCapacity_above_6 int,
               Brand_new_vehicles int,
               Pre_owned_vehicles int,
               category_Non_Transport int,
               category_Transport int
               );
               
create table fact_TS_iPASS (
               dist_code varchar(10),
               Month date,
               Sector varchar(100),
               investment_in_cr float,
               number_of_employes int
               );
               
			
              