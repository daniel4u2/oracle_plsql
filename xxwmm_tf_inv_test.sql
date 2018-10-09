create or replace procedure xxwmm_tf_inv_test(p_test_type IN VARCHAR2,
                                   p_vendor_num IN VARCHAR2 DEFAULT NULL,
                                   p_inv_type IN VARCHAR2 DEFAULT 'STANDARD',
                                   p_inv_currency IN VARCHAR2 DEFAULT 'GBP',
                                   p_inv_cnt  IN NUMBER DEFAULT 0, 
                                   p_inv_net_amt IN NUMBER DEFAULT 1000,
                                   p_tax_category_id IN VARCHAR2 DEFAULT 'S',
                                   p_tax_rate IN NUMBER DEFAULT 0.2,                                   
                                   p_inv_line_cnt IN NUMBER DEFAULT 2,
                                   p_po_num   IN VARCHAR2 DEFAULT NULL) IS
                                   
  v_inv_num VARCHAR2(30); 
  
  v_ref_num VARCHAR2(30); 
  
  v_batch_num VARCHAR2(60); 
  
  n_inv_cnt NUMBER := 0;
  
  n_tot_inv_cnt NUMBER :=0;
  n_tot_line_cnt NUMBER :=0;
  
  
  n_inv_net_amt NUMBER := 0;
  n_inv_tax_amt NUMBER := 0;
  
  n_inv_line_tax_amt NUMBER := 0;
  n_inv_line_net_amt NUMBER := 0;
  
  N_LAST_LINE_NET_AMT NUMBER := 0;
  N_LAST_LINE_tax_AMT NUMBER := 0;
 
  
  n_tot_line_net_amt NUMBER :=0;
  n_tot_line_tax_amt NUMBER := 0;
  
  n_line_qty  NUMBER :=0;
  n_unit_price NUMBER :=0;
  
  n_lin_num number :=0;
  v_vendor_num VARCHAR2(60);
  n_po_amount NUMBER;
  n_billed_amount NUMBER;
  n_po_header_id NUMBER;
  
  n_open_line_cnt  NUMBER :=0;
  
  

BEGIN

  --test comments--
  n_inv_net_amt := p_inv_net_amt;
  n_inv_tax_amt := ROUND( p_inv_net_amt * p_tax_rate,2);
  
 IF p_test_type = 'INV' THEN
 
   FOR I IN 1..p_inv_cnt LOOP
   
     n_inv_line_net_amt :=0;
     n_inv_line_tax_amt :=0;
     n_tot_line_net_amt :=0;
     n_tot_line_tax_amt :=0;
     N_LAST_LINE_NET_AMT :=0;
     N_LAST_LINE_tax_AMT :=0;
     
   
     n_inv_cnt := n_inv_cnt + 1;
   
     v_inv_num := 'TF_INV_'||TO_CHAR(SYSDATE,'SSMIHH24DDMMYYYY')||'_'||LPAD(n_inv_cnt,4,0);
     
     v_ref_num := 'ref_'||TO_CHAR(SYSDATE,'SSMIHH24DDMMYYYY')||'_'||LPAD(n_inv_cnt,4,0);
     
     v_batch_num := 'TF-INV-BATCH-'||TO_CHAR(SYSDATE,'SSMIHH24DDMMYYYY')||'_'||LPAD(n_inv_cnt,4,0);
   
       Insert into XXWMM_TF_INV_HEADERS_STAGING (INVOICE_NUM,INVOICE_TYPE,REFERENCE_ID,INVOICE_DATE,INVOICE_RECEIVED_DATE,INVOICE_CURRENCY,PO_NUMBER,INVOICE_REF,VENDOR_NUM,VENDOR_SITE_CODE,VENDOR_SITE_ID,INVOICE_AMOUNT,INV_TAX_AMOUNT,DESCRIPTION,SOURCE,REQUESTER,INV_URL,INV_BATCH_REF,INV_SEQUENCE_ID,STAGE_DATE,PROCESSED_DATE,RECORD_STATUS,STATUS_MSG,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE9,ATTRIBUTE10,ATTRIBUTE11,ATTRIBUTE12,ATTRIBUTE13,ATTRIBUTE14,ATTRIBUTE15,ORG_ID,ENRICH_REQ_ID) 
       values (v_inv_num,p_inv_type,v_ref_num,sysdate,sysdate - 3,p_inv_currency,null,null,p_vendor_num,null,null,ROUND(n_inv_net_amt+ n_inv_tax_amt),n_inv_tax_amt,'Requestor Contact Mail tcc@mail.com','TRADESHIFT',null,'https://sandbox.tradeshift.com/#/Tradeshift.ConversationLG/view/6e258b5b-109c-543e-bc31-e2dab17fcc7f',v_batch_num,1,sysdate,NULL,'N',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
       
       n_tot_inv_cnt := n_tot_inv_cnt + 1;

       FOR J IN 1 .. p_inv_line_cnt LOOP
       
         
        IF j =  p_inv_line_cnt then
        
          N_LAST_LINE_NET_AMT := n_inv_net_amt - n_tot_line_net_amt;
          N_LAST_LINE_tax_AMT := n_inv_tax_amt - n_tot_line_tax_amt;
          
          INSERT INTO XXWMM.XXWMM_TF_INV_LINES_STAGING (INV_LINE_NUM, INV_BATCH_REF,INV_SEQUENCE_ID,INV_LINE_TYPE,INV_LINE_AMOUNT,INV_LINE_TAX_AMT,TAX_CODE,TAX_RATE,INV_LINE_DESC,ITEM_DESC,LINE_QTY,LINE_PRICE,LINE_UOM,STAGE_DATE,RECORD_STATUS)
          VALUES
          (J,v_batch_num,'1',NULL,N_LAST_LINE_NET_AMT,N_LAST_LINE_tax_AMT,p_tax_category_id,p_tax_rate*100,NULL,NULL,1,N_LAST_LINE_NET_AMT,'EA',sysdate,'N');
            
          n_tot_line_cnt := n_tot_line_cnt + 1;    
        ELSE         
       
         n_inv_line_net_amt := ROUND(n_inv_net_amt / p_inv_line_cnt,2);
         n_inv_line_tax_amt := ROUND(n_inv_line_net_amt * p_tax_rate,2);
         
         n_tot_line_net_amt := n_tot_line_net_amt + n_inv_line_net_amt;
         n_tot_line_tax_amt := n_tot_line_tax_amt + n_inv_line_tax_amt;
       
        INSERT INTO XXWMM.XXWMM_TF_INV_LINES_STAGING (INV_LINE_NUM, INV_BATCH_REF,INV_SEQUENCE_ID,INV_LINE_TYPE,INV_LINE_AMOUNT,INV_LINE_TAX_AMT,TAX_CODE,TAX_RATE,INV_LINE_DESC,ITEM_DESC,LINE_QTY,LINE_PRICE,LINE_UOM,STAGE_DATE,RECORD_STATUS)
        VALUES
        (J,v_batch_num,'1',NULL,n_inv_line_net_amt,n_inv_line_tax_amt,p_tax_category_id,p_tax_rate*100,NULL,NULL,1,n_inv_line_net_amt,'EA',sysdate,'N');
        
        n_tot_line_cnt := n_tot_line_cnt + 1;
        
      END IF;
            
      END LOOP;
   
   END LOOP;
   
 
 ELSIF p_test_type = 'PO' THEN
 
  
     SELECT COUNT(1) 
          INTO n_open_line_cnt
          FROM po_headers_all poh,
               po_lines_all pol
         WHERE poh.segment1 = p_po_num
           AND poh.po_header_id = pol.po_header_id
           AND NVL(pol.closed_code,'OPEN')     NOT IN ('FINALLY CLOSED','CLOSED') 
           AND NVL(pol.cancel_flag,'N')        <> 'Y';
           

     
    IF n_open_line_cnt > 0 THEN
    
       dbms_output.put_line('Total Open Line Count = '||n_open_line_cnt);
           
       n_inv_line_net_amt :=0;
       n_inv_line_tax_amt :=0;
       n_tot_line_net_amt :=0;
       n_tot_line_tax_amt :=0;
       N_LAST_LINE_NET_AMT :=0;
       N_LAST_LINE_tax_AMT :=0;
       
       SELECT sup.segment1,
              poh.po_header_id
          INTO v_vendor_num,
               n_po_header_id
        FROM
          po_headers_all poh,
          ap_suppliers sup
        where poh.vendor_id = sup.vendor_id
          and poh.segment1 = p_po_num;
       
     
       n_inv_cnt := n_inv_cnt + 1;
     
       v_inv_num := 'TF_INV_'||TO_CHAR(SYSDATE,'SSMIHH24DDMMYYYY')||'_'||LPAD(n_inv_cnt,4,0);
       
       v_ref_num := 'ref_'||TO_CHAR(SYSDATE,'SSMIHH24DDMMYYYY')||'_'||LPAD(n_inv_cnt,4,0);
       
       v_batch_num := 'TF-INV-BATCH-'||TO_CHAR(SYSDATE,'SSMIHH24DDMMYYYY')||'_'||LPAD(n_inv_cnt,4,0);
       
       
          n_po_amount := po_core_s.get_total('H', n_po_header_id);
          
         SELECT nvl(SUM(nvl(pd.amount_billed,0)),0)
           INTO n_billed_amount
           FROM po_distributions_all pd
          WHERE pd.po_header_id = n_po_header_id
            AND pd.distribution_type != 'SCHEDULED'; --bug7033803   
            
          n_inv_net_amt := n_po_amount - n_billed_amount;
          n_inv_tax_amt := ROUND(n_inv_net_amt * p_tax_rate,2);            
     
         Insert into XXWMM_TF_INV_HEADERS_STAGING (INVOICE_NUM,INVOICE_TYPE,REFERENCE_ID,INVOICE_DATE,INVOICE_RECEIVED_DATE,INVOICE_CURRENCY,PO_NUMBER,INVOICE_REF,VENDOR_NUM,VENDOR_SITE_CODE,VENDOR_SITE_ID,INVOICE_AMOUNT,INV_TAX_AMOUNT,DESCRIPTION,SOURCE,REQUESTER,INV_URL,INV_BATCH_REF,INV_SEQUENCE_ID,STAGE_DATE,PROCESSED_DATE,RECORD_STATUS,STATUS_MSG,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE9,ATTRIBUTE10,ATTRIBUTE11,ATTRIBUTE12,ATTRIBUTE13,ATTRIBUTE14,ATTRIBUTE15,ORG_ID,ENRICH_REQ_ID) 
         values (v_inv_num,p_inv_type,v_ref_num,sysdate,sysdate - 3,p_inv_currency,p_po_num,null,v_vendor_num,null,null,ROUND(n_inv_net_amt+ n_inv_tax_amt,2),n_inv_tax_amt,'Requestor Contact Mail tcc@mail.com','TRADESHIFT',null,'https://sandbox.tradeshift.com/#/Tradeshift.ConversationLG/view/6e258b5b-109c-543e-bc31-e2dab17fcc7f',v_batch_num,1,sysdate,NULL,'N',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
         
         n_tot_inv_cnt := n_tot_inv_cnt + 1;  
         
    FOR r_lines IN (
        SELECT line_num,
          shipment_num,
          open_line_amount,
          unbilled_qty,
          unit_price
      FROM 
      ( SELECT pla.line_num,
            pll.shipment_num,
            SUM(nvl(pda.amount_billed,0)) billed_line_amount,
            SUM(NVL(pll.quantity,0)) * MAX(pla.unit_price) - SUM(nvl(pda.amount_billed,0)) open_line_amount,
            SUM(NVL(pll.quantity,0)) - SUM(NVL(pll.quantity_billed,0)) unbilled_qty,
            MAX(pla.unit_price) unit_price
            FROM 
            po_headers_all poh,
            po_lines_all pla,
            po_line_locations_all pll,
            po_distributions_all pda
            WHERE poh.po_header_id = pla.po_header_id-- 2635708
              AND pla.po_line_id = pll.po_line_id
              AND pll.line_location_id = pda.line_location_id
              AND NVL(pll.closed_code,'OPEN')     NOT IN ('FINALLY CLOSED','CLOSED') 
              AND NVL(pll.cancel_flag,'N')        <> 'Y'   
              AND poh.segment1 = p_po_num
            GROUP BY pla.line_num,pll.shipment_num 
            ) pls
         ) LOOP
    
         n_lin_num := n_lin_num + 1;
         
         n_line_qty := 0;
         n_unit_price :=0;
         
         n_line_qty := r_lines.unbilled_qty;
         n_unit_price := r_lines.open_line_amount / r_lines.unbilled_qty;         
        
        IF n_lin_num =  n_open_line_cnt then
        
          dbms_output.put_line('The last invoice line = '||n_lin_num);
        
    
          N_LAST_LINE_NET_AMT := n_inv_net_amt - n_tot_line_net_amt;
          N_LAST_LINE_tax_AMT := n_inv_tax_amt - n_tot_line_tax_amt;
          
          INSERT INTO XXWMM.XXWMM_TF_INV_LINES_STAGING (INV_LINE_NUM, INV_BATCH_REF,INV_SEQUENCE_ID,INV_LINE_TYPE,INV_LINE_AMOUNT,INV_LINE_TAX_AMT,TAX_CODE,TAX_RATE,INV_LINE_DESC,ITEM_DESC,LINE_QTY,LINE_PRICE,LINE_UOM,STAGE_DATE,RECORD_STATUS)
          VALUES
          (n_lin_num,v_batch_num,'1',NULL,N_LAST_LINE_NET_AMT,N_LAST_LINE_tax_AMT,p_tax_category_id,p_tax_rate*100,NULL,NULL,n_line_qty,n_unit_price,'EA',sysdate,'N');
            
          n_tot_line_cnt := n_tot_line_cnt + 1;    
        ELSE         
       
         n_inv_line_net_amt := r_lines.open_line_amount;
         n_inv_line_tax_amt := ROUND(n_inv_line_net_amt * p_tax_rate,2);
         

         
         n_tot_line_net_amt := n_tot_line_net_amt + n_inv_line_net_amt;
         n_tot_line_tax_amt := n_tot_line_tax_amt + n_inv_line_tax_amt;
       
        INSERT INTO XXWMM.XXWMM_TF_INV_LINES_STAGING (INV_LINE_NUM, INV_BATCH_REF,INV_SEQUENCE_ID,INV_LINE_TYPE,INV_LINE_AMOUNT,INV_LINE_TAX_AMT,TAX_CODE,TAX_RATE,INV_LINE_DESC,ITEM_DESC,LINE_QTY,LINE_PRICE,LINE_UOM,STAGE_DATE,RECORD_STATUS)
        VALUES
        (n_lin_num,v_batch_num,'1',NULL,n_inv_line_net_amt,n_inv_line_tax_amt,p_tax_category_id,p_tax_rate*100,NULL,NULL,n_line_qty,n_unit_price,'EA',sysdate,'N');
        
        n_tot_line_cnt := n_tot_line_cnt + 1;
        
      END IF;   
    
    END LOOP;         
           
    END IF;
 
 END IF;

 COMMIT;
 
 DBMS_OUTPUT.PUT_LINE('Total '||n_tot_inv_cnt||' Header Records Inserted ');
 DBMS_OUTPUT.PUT_LINE('Total '||n_tot_line_cnt||' Line Records Inserted ');
 
EXCEPTION WHEN OTHERS THEN

 ROLLBACK;
 
END;
