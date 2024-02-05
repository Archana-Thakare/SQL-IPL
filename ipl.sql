create table matches(id	integer,season	integer, city varchar,date	date,	team1 varchar,	
					 team2 varchar,	toss_winner varchar,	toss_decision varchar,	result varchar,	
					 dl_applied	integer,winner	varchar, win_by_runs integer,	win_by_wickets integer,
					 player_of_match varchar,	venue varchar,	umpire1	varchar, umpire2 varchar,	
					 umpire3 varchar);
create table deliveries (match_id integer,	inning integer,	batting_team varchar,	bowling_team varchar,
						 over integer,	ball integer,	batsman	varchar,non_striker	varchar,
						 bowler	varchar,is_super_over integer,	wide_runs integer,	bye_runs integer,
						 legbye_runs integer,	noball_runs	integer,penalty_runs integer,
						 batsman_runs integer,	extra_runs	integer,total_runs	integer,
						 player_dismissed varchar,	dismissal_kind	varchar,fielder varchar);


/*copy data*/
copy deliveries from 'C:\archana\internshala\sql\eda_ipl-main\deliveries.csv' with (format 'csv', header true);
copy matches from 'C:\archana\internshala\sql\eda_ipl-main\matches.csv' with (format 'csv', header true);


/*select 10 players with hight striking rate*/
select *,round((total_run_till_now * 1.0/balls_faced)*100,2) as SR  from (select  batsman,count(*) as
		balls_faced,sum(batsman_runs) as total_run_till_now    from deliveries 	where wide_runs=0
		group by batsman  )  where balls_faced>=500 order by SR desc limit 10;
		
/*select 10 players with average*/

 select *,round(a.total_run *1.0/dismissals,2) as average from   (select count(distinct season ) as season_count,batsman,sum(batsman_runs)as total_run from
  	(select match_id, season,batsman, batsman_runs from deliveries inner join matches on match_id=id)group by batsman) as a inner join
	(select  distinct player_dismissed, count(player_dismissed)as dismissals from deliveries group by player_dismissed) as b
	on a.batsman=b.player_dismissed where season_count>=2 order by average desc limit 10;
	
  
  
/*select 10 players with boundry*/
select * from (select batsman, sum(batsman_runs) as boundry,count(distinct season) as total_season 
			   from (select a.*,b.* from deliveries as a inner join matches as b 
 on a.match_id=b.id)where batsman_runs>=4 group by batsman )where total_season>=2 order by boundry desc limit 10;
 
/*select 10 economy fielder*/
select * ,round(runs_given * 1.0/total_ball/6,2) as economy_rate from (select bowler as economy_bowler, 
	sum(total_runs) as runs_given,count(*) as total_ball from deliveries group by bowler) where  
	total_ball>=500 order by economy_rate asc limit 10;
	
/*select 10 bowlers with the best strike rate*/
select *,round(total_bowl*1.0/wicket,2) as strike_rate from (select bowler as strike_bowler,count(*)as total_bowl,
	count (case when player_dismissed is not null then 1 end) as wicket from deliveries group by bowler)
	where total_bowl>=500 order by strike_rate asc limit 10;

/*select 10 all rounder with the best strike rate*/
select a.*,b.* from (select *,round((total_run_till_now * 1.0/balls_faced)*100,2) as SR  from (select  batsman,count(*) as
		balls_faced,sum(batsman_runs) as total_run_till_now    from deliveries 	where wide_runs=0
		group by batsman  )  where balls_faced>=500) as a inner join
		
	(select *,round(total_bowl*1.0/wicket,2) as strike_rate from (select bowler as strike_bowler,count(*)as total_bowl,
	count (case when player_dismissed is not null then 1 end) as wicket from deliveries group by bowler)
	where total_bowl>=300) as b
	on a.batsman=b.strike_bowler
	order by SR desc , strike_rate desc limit 10
	
/*1 Get the count of cities that have hosted an IPL match*/
select count(distinct  city) from matches as Total_city

	
/*2Create table deliveries_v02 with all the columns of the table ‘deliveries’ and an additional column ball_result containing values boundary, dot or other depending on the total_run (boundary for >= 4, dot for 0 and other for any other number)
(Hint 1 : CASE WHEN statement is used to get condition based results)
(Hint 2: To convert the output data of the select statement into a table, you can use a subquery. Create table table_name as [entire select statement].
*/
create table deliveries_v02 as (select * ,case when total_runs>=4 then 'boundry'
											when total_runs=0 then 'dot'
											else 'other'
											end as ball_result from deliveries )
							

/*3.Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table.*/
select * from (select count(*) as boundry_balls from deliveries_v02 where ball_result in ('boundry')) cross join
	(select count(*) as boundry_balls from deliveries_v02 where ball_result in ('dot')) 

/*4.Write a query to fetch the total number of boundaries scored by each team from the deliveries_v02 table and order
it in descending order of the number of boundaries scored.*/
select batting_team, count(ball_result)as Total_boundry from deliveries_v02 where ball_result = 'boundry' 
	group by batting_team order by Total_boundry desc

/*5. Write a query to fetch the total number of dot balls bowled by each team and order it in descending order 
of the total number of dot balls bowled.*/
select bowling_team, count(ball_result)as dot_balls_bowled from deliveries_v02 where ball_result = 'dot' 
	group by bowling_team order by dot_balls_bowled desc

/*6.Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA*/
select count(player_dismissed) from deliveries_v02 where player_dismissed is not null and dismissal_kind is null

/*7Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table*/
select bowler, sum(extra_runs) as total_extra_run from deliveries_v02 group by bowler order by total_extra_run desc 

/*8Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02 table and two additional
column (named venue and match_date) of venue and date from table matches*/
create table deliveries_v03 as (select a.*,b.venue, b.date from deliveries_v02 as a left join matches as b
								on a.match_id=b.id )
/*9.Write a query to fetch the total runs scored for each venue and order it in the descending order 
 of total runs scored.*/
 select sum(total_runs)as total_runs_scored from deliveries_v03 group by venue order by total_runs_scored desc 

/*10. Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of 
total runs scored.*/
select sum(total_runs)as total_runs_scored,  extract(year from date) as season from deliveries_v03 
  where venue= 'Eden Gardens' group by season 
  