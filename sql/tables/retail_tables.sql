CREATE TABLE [retail].[carriers] (
    [car_id] varchar(8000) NULL,
    [car_name] varchar(8000) NULL,
    [serv_level] varchar(8000) NULL,
    [has_cold_chain_capa] bit NULL,
    [supp_ph] varchar(8000) NULL
);
CREATE TABLE [retail].[customers] (
    [cust_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [cust_email] varchar(8000) NULL,
    [loya_tier] varchar(8000) NULL,
    [is_active_cust] bit NULL,
    [sign_up_dt] datetime2 NULL,
    [life_val_amt] float NULL
);
CREATE TABLE [retail].[demand_signals] (
    [dem_signal_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [dem_chn] varchar(8000) NULL,
    [signal_src_sys] varchar(8000) NULL
);
CREATE TABLE [retail].[forecasts] (
    [fcst_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [dem_signal_id] varchar(8000) NULL,
    [fcst_hor_days] bigint NULL,
    [fcst_mdl_name] varchar(8000) NULL
);
CREATE TABLE [retail].[inventories] (
    [inv_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [wh_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [sfty_stock_qty] bigint NULL,
    [reord_pt_qty] bigint NULL,
    [lead_t_days] bigint NULL
);
CREATE TABLE [retail].[order_fulfillment] (
    [fulfill_id] bigint NULL,
    [ord_id] varchar(8000) NULL,
    [origin_str_id] varchar(8000) NULL,
    [fulfill_str_id] varchar(8000) NULL,
    [shp_id] varchar(8000) NULL,
    [fulfill_type] varchar(8000) NULL,
    [fulfill_status] varchar(8000) NULL,
    [assigned_dt] datetime2 NULL,
    [picked_dt] datetime2 NULL,
    [packed_dt] datetime2 NULL,
    [shipped_dt] datetime2 NULL,
    [distance_miles] decimal(7,2) NULL
);
CREATE TABLE [retail].[order_lines] (
    [ord_ln_id] varchar(8000) NULL,
    [ord_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [qty] bigint NULL,
    [unit_price_amt] float NULL,
    [ln_total_amt] float NULL
);
CREATE TABLE [retail].[orders] (
    [ord_id] varchar(8000) NULL,
    [cust_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [ord_dt] datetime2 NULL,
    [ord_status] varchar(8000) NULL,
    [is_expe] bit NULL,
    [ord_total_amt] float NULL,
    [paym_method_type] varchar(8000) NULL
);
CREATE TABLE [retail].[product_categories] (
    [prod_cat_id] varchar(8000) NULL,
    [cat_name] varchar(8000) NULL,
    [depa_name] varchar(8000) NULL,
    [is_peri] bit NULL,
    [shelf_life_days] bigint NULL
);
CREATE TABLE [retail].[products] (
    [prod_id] varchar(8000) NULL,
    [prod_cat_id] varchar(8000) NULL,
    [sku] varchar(8000) NULL,
    [prod_name] varchar(8000) NULL,
    [brand_name] varchar(8000) NULL,
    [is_disc] bit NULL,
    [launch_dt] datetime2 NULL,
    [unit_cost_amt] float NULL
);
CREATE TABLE [retail].[promotions] (
    [promo_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [promo_name] varchar(8000) NULL,
    [start_dt] datetime2 NULL,
    [end_dt] datetime2 NULL,
    [disc_pct] float NULL,
    [is_active_promo] bit NULL
);
CREATE TABLE [retail].[recommendations] (
    [report_date] varchar(8000) NULL,
    [str_id] varchar(8000) NULL,
    [str_name] varchar(8000) NULL,
    [str_type] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [reg_name] varchar(8000) NULL,
    [insight_type] varchar(8000) NULL,
    [severity] varchar(8000) NULL,
    [domain] varchar(8000) NULL,
    [title] varchar(8000) NULL,
    [detail] varchar(8000) NULL,
    [reasoning] varchar(8000) NULL,
    [dollar_impact] real NULL,
    [generated_at] varchar(8000) NULL
);
CREATE TABLE [retail].[regions] (
    [reg_id] varchar(8000) NULL,
    [reg_name] varchar(8000) NULL,
    [coun_code] varchar(8000) NULL,
    [time_name] varchar(8000) NULL,
    [is_cold_chain_requ] bit NULL
);
CREATE TABLE [retail].[returns] (
    [rtn_id] varchar(8000) NULL,
    [ord_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [rtn_dt] datetime2 NULL,
    [rtn_rsn] varchar(8000) NULL,
    [rfnd_amt] float NULL
);
CREATE TABLE [retail].[shipments] (
    [shp_id] varchar(8000) NULL,
    [ord_id] varchar(8000) NULL,
    [car_id] varchar(8000) NULL,
    [wh_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [trac_num] varchar(8000) NULL,
    [shp_status] varchar(8000) NULL,
    [ship_dt] datetime2 NULL,
    [est_deli_dt] datetime2 NULL,
    [act_deli_dt] datetime2 NULL
);
CREATE TABLE [retail].[store_inventory] (
    [str_inv_id] varchar(8000) NULL,
    [str_id] varchar(8000) NULL,
    [prod_id] varchar(8000) NULL,
    [snapshot_dt] date NULL,
    [on_hand_qty] int NULL,
    [on_order_qty] int NULL,
    [shrinkage_qty] int NULL,
    [last_received_dt] date NULL,
    [last_sold_dt] date NULL
);
CREATE TABLE [retail].[stores] (
    [str_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [str_name] varchar(8000) NULL,
    [str_type] varchar(8000) NULL,
    [open_dt] datetime2 NULL
);
CREATE TABLE [retail].[warehouses] (
    [wh_id] varchar(8000) NULL,
    [reg_id] varchar(8000) NULL,
    [wh_name] varchar(8000) NULL,
    [addr_line1] varchar(8000) NULL,
    [city_name] varchar(8000) NULL,
    [state_or_prov] varchar(8000) NULL,
    [postal_code] varchar(8000) NULL,
    [is_cross_dock] bit NULL
);
