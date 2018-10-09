create or replace package XXWMM_TF_INV_INT_PKG
/***************************************************************************
* HeaderSVN:https://10.3.5.138/svnroot/ebs/EBS/trunk/Supplier Portal/Tradeshift to EBS Invoice Inbound/XXWMM_TF_INV_INT_PKG.pks,v1.0 2018/09/26 SYSDEVDL Exp $
*                                                                          *
*                   Configuration Item History Log                         *
*                                                                          *
****************************************************************************
*                                                                          *
* Program Name : XXWMM_TF_INV_INT_PKG.pks                                  *
* System       : Morrisons                                                 *
* SubSystem    : Morrisons Custom Application                              *
* Title        : Morrisons Create Package                                  *
*                                                                          *
****************************************************************************
*                                                                          *
* Function     : This SQL*Plus script is used to create database package   *
*                body for the Tradeshift to EBS invoice interface.         *
*                                                                          *
****************************************************************************
* Version Date Issued Author of    Change Req./  Brief Description of      *
* Number              Modification OR/FR No.     Modification              *
* ======= =========== ============ ============= ========================= *
* 1.0     26 Sep 2018 Daniel Li                  Created.                  *=
****************************************************************************
*                                                                          *
*                       Additional Information                             *
*                                                                          *
****************************************************************************
*                                                                          *
* Usage        : sqlplus APPS/APPS_PW  @XXWMM_STEP_EBS_SUP_PKG.pks   *
*                                                                          *
***************************************************************************/

AS

  -- Declaring the global variables
  g_source                         VARCHAR2(80);
  g_debug_switch                   VARCHAR2(1) := 'N';
  g_inv_sysdate                    DATE;
  g_program_application_id         NUMBER;
  g_program_id                     NUMBER;
  g_conc_request_id                NUMBER;
  g_invoices_table                 VARCHAR2(30);
  g_invoice_lines_table            VARCHAR2(30);
  g_segment_delimiter              VARCHAR2(10);

  g_invoice_base_currency          VARCHAR2(3) := 'GBP';

  --Staging record status
  g_stg_rec_new_flag               VARCHAR2(1) := 'N';
  g_stg_rec_warn_flag              VARCHAR2(1) := 'W';
  g_stg_rec_err_flag               VARCHAR2(1) := 'E';
  g_stg_rec_com_flag               VARCHAR2(1) := 'P';
  g_stg_rec_imp_flag               VARCHAR2(1) := 'I';
  g_stg_rec_upd_flag               VARCHAR2(1) := 'U';
  g_stg_rec_pst_flag               VARCHAR2(1) := 'Z';

  g_org_id_supermarkets  CONSTANT  NUMBER := 82;
  g_sob_id_supermarkets  CONSTANT  NUMBER := 2022;
  g_ledger_supermarkets  CONSTANT  VARCHAR2(60) :='Wm Morrison Supermarkets (GB)';

  g_log_level            CONSTANT  NUMBER          DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_LOG_LEVEL');
  --Profile to control if the enrich process doing the PO matching
  g_inv_match            CONSTANT  VARCHAR2(30)    DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_PO_MATCH');

  --Profile to control if the enrich process doing the multiple PO lines matching
  g_inv_line_match            CONSTANT  VARCHAR2(30)    DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_PO_LINE_MATCH');

  --Profile to set the invoice amount check against the Open PO amount
  g_inv_match_tol  CONSTANT  NUMBER          DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_MATCH_TOL');

  --Profile to set the invoice line amount check against the Open PO line amount
  g_inv_line_match_tol  CONSTANT  NUMBER          DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_LINE_MATCH_TOL');

  --Profile to set the invoice line qty check against the PO un-billed line qty
  g_inv_match_qty_tol  CONSTANT  NUMBER          DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_MATCH_QTY_TOL');

  --Profile to set the invoice line price check against the PO ordered unit price
  g_inv_match_price_tol  CONSTANT  NUMBER          DEFAULT FND_PROFILE.VALUE('WMM_TF_INV_MATCH_PRICE_TOL');

  --Default tax code in case of no tax code mapping found
  g_default_tax_code     CONSTANT VARCHAR2(60)  := 'GB MIXED';

  g_req_max_wait              CONSTANT NUMBER := 7200;

  g_req_wait_int              CONSTANT NUMBER := 10;

  --Open Invoice Import Concurrent Program Name
  g_con_ap_imp_process     CONSTANT VARCHAR2(60)  := 'XXWMMTRSINVIMP';

  --Post Process Concurrent Program Name
  g_con_inv_post_process    CONSTANT VARCHAR2(60)  := 'XXWMM_TF_INV_INT_POST';

  --Payable Invoice Validation Concurrent Program Name
  g_con_inv_val_process    CONSTANT VARCHAR2(60)  := 'APPRVL';

  --Payable Creat Accounting Concurrent Program Name
  g_con_inv_acct_process    CONSTANT VARCHAR2(60)  := 'XLAACCPB';

  --Invoice Approval Workflow Concurrent Program Name
  g_con_inv_apw_process     CONSTANT VARCHAR2(60)  := 'APXIAWRE';

  --g_bulk_limit           CONSTANT  NUMBER := 1000;

  TYPE r_import_setup_rec IS RECORD
  (source_name     FND_LOOKUP_VALUES_VL.meaning%TYPE,
   batch_name      FND_LOOKUP_VALUES_VL.description%TYPE,
   gl_date         FND_LOOKUP_VALUES_VL.tag%TYPE,
   group_id        FND_LOOKUP_VALUES_VL.attribute1%TYPE,
   hold_name       FND_LOOKUP_VALUES_VL.attribute2%TYPE,
   hold_reason     FND_LOOKUP_VALUES_VL.attribute3%TYPE,
   purge           FND_LOOKUP_VALUES_VL.attribute4%TYPE,
   trace_switch    FND_LOOKUP_VALUES_VL.attribute5%TYPE,
   debug_switch    FND_LOOKUP_VALUES_VL.attribute6%TYPE,
   summary_report  FND_LOOKUP_VALUES_VL.attribute7%TYPE,
   commit_size     FND_LOOKUP_VALUES_VL.attribute8%TYPE,
   user_id         FND_LOOKUP_VALUES_VL.attribute9%TYPE,
   login_id        FND_LOOKUP_VALUES_VL.attribute10%TYPE,
   archive_days    FND_LOOKUP_VALUES_VL.attribute11%TYPE,
   batch_id        NUMBER);

  --Collection indexed by the invoice source code
  TYPE t_import_setup_tab is TABLE of r_import_setup_rec
                 index by VARCHAR2(30);

  TYPE t_invoice_table is TABLE of AP_INVOICES_INTERFACE%ROWTYPE
                 index by BINARY_INTEGER;

  TYPE t_lines_table is TABLE OF AP_INVOICE_LINES_INTERFACE%ROWTYPE
                 index by BINARY_INTEGER;

PROCEDURE IMP_POST_PRO(o_errorbuf             OUT            VARCHAR2,
                       o_retcode              OUT            VARCHAR2,
                       p_inv_batch_ref        IN             VARCHAR2,
                       p_commit_cycle         IN             NUMBER);


PROCEDURE IMPORT_INVOICES(
    o_errorbuf             OUT            VARCHAR2,
    o_retcode              OUT            VARCHAR2,
    p_org_id               IN             NUMBER,
    p_source               IN             VARCHAR2,
    p_batch_name           IN             VARCHAR2,
    p_gl_date              IN             DATE,
    p_ap_imp_proc_flag     IN             VARCHAR2,
    p_post_proc_flag       IN             VARCHAR2,
    p_validate_proc_flag   IN             VARCHAR2,
    p_account_proc_flag    IN             VARCHAR2,
    p_approval_proc_flag   IN             VARCHAR2,
	  p_debug_switch         IN             VARCHAR2 DEFAULT 'N',
	  p_commit_cycles        IN             NUMBER);


END XXWMM_TF_INV_INT_PKG;