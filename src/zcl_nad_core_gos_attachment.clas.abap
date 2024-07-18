*----------------------------------------------------------------------*
*       CLASS ZCL_NAD_CORE_GOS_ATTACHMENT DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS ZCL_NAD_CORE_GOS_ATTACHMENT DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES /NEPTUNE/IF_NAD_SERVER .

    TYPES:
      BEGIN OF TY_ATTACHMENT,
            INSTID       TYPE STRING,
            TYPEID       TYPE STRING,
            INSTID_B     TYPE SOFOLENTI1-DOC_ID,
            DESCRIPTION  TYPE STRING,
            FILE_EXT     TYPE STRING,
            FILE_SIZE    TYPE STRING,
            CREAT_NAME   TYPE STRING,
            CREAT_FNAM   TYPE STRING,
            CREAT_DATE   TYPE STRING,
            CREAT_TIME   TYPE STRING,
            CONTENT      TYPE STRING,
            DELETE       TYPE BOOLEAN,
      END OF TY_ATTACHMENT .
    TYPES:
        BEGIN OF TY_CONTEXT,
              INSTID       TYPE CHAR20,
              APPLID       TYPE CHAR20,
        END OF TY_CONTEXT .
    DATA:
      IT_ATTACHMENT TYPE STANDARD TABLE OF TY_ATTACHMENT .
    DATA:
      IT_ATTACH_NEW TYPE STANDARD TABLE OF TY_ATTACHMENT .
    DATA WA_ATTACHMENT TYPE TY_ATTACHMENT .
    DATA WA_CONTEXT TYPE TY_CONTEXT.
protected section.
private section.

  methods GET_ATTACHMENT_LIST
    importing
      !AJAX_VALUE type STRING .
  methods GET_ATTACHMENT_DATA
    importing
      !SERVER type ref to /NEPTUNE/CL_NAD_SERVER
      !KEY type STRING .
  methods SAVE_ATTACHMENT .
ENDCLASS.



CLASS ZCL_NAD_CORE_GOS_ATTACHMENT IMPLEMENTATION.


method /neptune/if_nad_server~handle_on_ajax.


  case ajax_id.

    when 'GET_LIST'.
      call method get_attachment_list( ajax_value ).

    when 'SAVE'.
      call method save_attachment( ).

  endcase.


endmethod.


method /neptune/if_nad_server~handle_on_request.


  case key_id.

    when 'GET_ATTACHMENT'.
      call method get_attachment_data
        exporting
          key    = key
          server = server.

  endcase.


endmethod.


method get_attachment_data.

data: lv_doc_id     type sofolenti1-doc_id,
      lv_content    type xstring,
      lv_mime_type  type string,
      lv_file_name  type string,
      lv_file_type  type string,
      lv_temp       type string,
      lv_length     type i,
      it_hex        type standard table of solix,
      it_header     type standard table of solisti1,
      wa_header     type solisti1,
      wa_hex        like line of it_hex,
      wa_doc        type sofolenti1.


  lv_doc_id = key.
  call function 'SO_DOCUMENT_READ_API1'
    exporting
      document_id                      = lv_doc_id
    importing
      document_data                    = wa_doc
    tables
      object_header                    = it_header
      contents_hex                     = it_hex
    exceptions
      document_id_not_exist            = 1
      operation_no_authorization       = 2
      x_error                          = 3
      others                           = 4.


* Build String
  lv_length = wa_doc-doc_size.

  call function 'SCMS_BINARY_TO_XSTRING'
    exporting
      input_length       = lv_length
    importing
      buffer             = lv_content
    tables
      binary_tab         = it_hex
    exceptions
      failed             = 1
      others             = 2.

* Filename
  read table it_header into wa_header index 1.

  split wa_header at '=' into lv_temp
                              lv_file_name.

  split lv_file_name at '.' into lv_temp
                                 lv_file_type.

  translate lv_file_type to upper case.


* Set Document Response
  case lv_file_type.

    when 'PDF'.
      lv_mime_type = 'application/pdf'.

    when 'JPG'.
      lv_mime_type = 'image/jpg'.

    when 'JPEG'.
      lv_mime_type = 'image/jpeg'.

    when 'GIF'.
      lv_mime_type = 'image/gif'.

    when 'DOCX'.
      lv_mime_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'.

    when 'DOC'.
      lv_mime_type = 'application/msword'.

    when 'XLS'.
      lv_mime_type = 'application/vnd.ms-excel'.

    when 'XLSX'.
      lv_mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

    when 'PPT'.
      lv_mime_type = 'application/vnd.ms-powerpoint'.

    when 'PPTX'.
      lv_mime_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'.

    when others.
      lv_mime_type = 'text/html'.

  endcase.

* Response
  call method server->api_response_xstring
    exporting
      data         = lv_content
      file_name    = lv_file_name
      content_type = lv_mime_type.


endmethod.


METHOD GET_ATTACHMENT_LIST.

  DATA: LV_INSTID_A   TYPE SRGBTBREL-INSTID_A,
        LV_DOC_ID     TYPE SOFOLENTI1-DOC_ID,
        IT_CONTENT    TYPE STANDARD TABLE OF SOLISTI1,
        IT_SRGBTBREL  TYPE STANDARD TABLE OF SRGBTBREL,
        WA_CONTENT    TYPE SOLISTI1,
        WA_SRGBTBREL  TYPE SRGBTBREL,
        WA_DOC        TYPE SOFOLENTI1,
        WA_SOFC       TYPE V_SOFC.

  DATA: BEGIN OF LV_KEY,
        FOLTP TYPE SO_FOL_TP,
        FOLYR TYPE SO_FOL_YR,
        FOLNO TYPE SO_FOL_NO,
        DOCTP TYPE SO_DOC_TP,
        DOCYR TYPE SO_DOC_YR,
        DOCNO TYPE SO_DOC_NO,
    END OF LV_KEY.


  DATA: LV_INSTID TYPE STRING,
        LV_TYPEID TYPE STRING.


* Get Object
  SPLIT AJAX_VALUE AT '|' INTO LV_TYPEID
                               LV_INSTID.




* Get GOS Relation
  SELECT *
         FROM SRGBTBREL
         INTO TABLE IT_SRGBTBREL
         WHERE INSTID_A EQ LV_INSTID
           AND TYPEID_A EQ LV_TYPEID
           AND RELTYPE  EQ 'ATTA'.

* Exceptions
  CASE LV_TYPEID.

    WHEN 'BUS2009'.

      " Get Header GOS
      SELECT *
             FROM SRGBTBREL
             APPENDING TABLE IT_SRGBTBREL
             WHERE INSTID_A EQ LV_INSTID(10)
               AND TYPEID_A EQ 'BUS2105'
               AND RELTYPE  EQ 'ATTA'.

  ENDCASE.
  SORT IT_SRGBTBREL BY INSTID_B.
  DELETE ADJACENT DUPLICATES FROM IT_SRGBTBREL COMPARING INSTID_B.
* Get Attachment/Comment
  LOOP AT IT_SRGBTBREL INTO WA_SRGBTBREL.

    LV_KEY = WA_SRGBTBREL-INSTID_B.

*   Get Document Info
    SELECT SINGLE *
           FROM V_SOFC
           INTO WA_SOFC
           WHERE FOLTP EQ LV_KEY-FOLTP
             AND FOLYR EQ LV_KEY-FOLYR
             AND FOLNO EQ LV_KEY-FOLNO
             AND DOCTP EQ LV_KEY-DOCTP
             AND DOCYR EQ LV_KEY-DOCYR
             AND DOCNO EQ LV_KEY-DOCNO.

    CHECK SY-SUBRC EQ 0.

    LV_DOC_ID = WA_SRGBTBREL-INSTID_B.
    CALL FUNCTION 'SO_DOCUMENT_READ_API1'
      EXPORTING
        DOCUMENT_ID                = LV_DOC_ID
      IMPORTING
        DOCUMENT_DATA              = WA_DOC
      EXCEPTIONS
        DOCUMENT_ID_NOT_EXIST      = 1
        OPERATION_NO_AUTHORIZATION = 2
        X_ERROR                    = 3
        OTHERS                     = 4.

    MOVE-CORRESPONDING WA_DOC TO WA_ATTACHMENT.
    WA_ATTACHMENT-INSTID      = WA_SRGBTBREL-INSTID_A.
    WA_ATTACHMENT-TYPEID      = WA_SRGBTBREL-TYPEID_A.
    WA_ATTACHMENT-INSTID_B    = WA_SRGBTBREL-INSTID_B.
    WA_ATTACHMENT-DESCRIPTION = WA_SOFC-DOCDES.
    WA_ATTACHMENT-FILE_EXT    = WA_SOFC-FILE_EXT.
    WA_ATTACHMENT-FILE_SIZE   = WA_SOFC-OBJLEN.

    SHIFT WA_ATTACHMENT-FILE_SIZE LEFT DELETING LEADING '0'.

    WA_ATTACHMENT-FILE_SIZE = WA_ATTACHMENT-FILE_SIZE / 1000.

    APPEND WA_ATTACHMENT TO IT_ATTACHMENT.
    CLEAR  WA_ATTACHMENT.


  ENDLOOP.

* Sorting
  SORT IT_ATTACHMENT BY CREAT_DATE DESCENDING CREAT_TIME DESCENDING.


ENDMETHOD.


METHOD SAVE_ATTACHMENT.

  DATA: LV_FOLDER_ID      TYPE SOODK,
        LV_OBJECT_ID      TYPE SOOBJINFI1-OBJECT_ID,
        LV_ROLEA          TYPE BORIDENT,
        LV_ROLEB          TYPE BORIDENT,
        LV_FILE_NAME(255) TYPE C,
        LV_FILE_TYPE(9)   TYPE C,
        LV_LENGTH         TYPE I,
        LV_LENGTH_F       TYPE I,
        LV_LENGTH_E       TYPE I,
        LV_PRE            TYPE STRING,
        LV_DATA           TYPE STRING,
        LV_DATAX          TYPE XSTRING,
        LV_DOC_TYPE       TYPE SOODK-OBJTP,
        LV_DOC_DATA       TYPE SODOCCHGI1,
        LV_DOC_INFO       TYPE SOFOLENTI1,
        LV_AJAX_VALUE     TYPE STRING,
        IT_SOLIX          TYPE STANDARD TABLE OF SOLIX,
        IT_HEADER         TYPE STANDARD TABLE OF SOLISTI1,
        WA_HEADER         TYPE SOLISTI1.


* Get Root Folder
  CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
    EXPORTING
      OWNER     = SY-UNAME
      REGION    = 'B'
    IMPORTING
      FOLDER_ID = LV_FOLDER_ID.

  LV_OBJECT_ID = LV_FOLDER_ID.

* Create New
  LOOP AT IT_ATTACH_NEW INTO WA_ATTACHMENT WHERE CONTENT IS NOT INITIAL.

*   Init
    CLEAR IT_HEADER.
    CLEAR IT_SOLIX.
    CLEAR LV_DATAX.

*   Split Mimetype
    SPLIT WA_ATTACHMENT-CONTENT AT ',' INTO LV_PRE
                                            LV_DATA.

*   Get Extension
    LV_FILE_NAME = WA_ATTACHMENT-DESCRIPTION.
    CALL FUNCTION 'TRINT_FILE_GET_EXTENSION'
      EXPORTING
        FILENAME  = LV_FILE_NAME
      IMPORTING
        EXTENSION = LV_FILE_TYPE.

*   Set Document Type
    CASE LV_FILE_TYPE.

      WHEN 'JPEF'.
        LV_DOC_TYPE = 'XLS'.

      WHEN 'XLSX'.
        LV_DOC_TYPE = 'XLS'.

      WHEN 'DOCX'.
        LV_DOC_TYPE = 'DOC'.

      WHEN 'PPTX'.
        LV_DOC_TYPE = 'PPT'.

      WHEN OTHERS.
        LV_DOC_TYPE = LV_FILE_TYPE.

    ENDCASE.

*   File Name
    LV_LENGTH_F  = STRLEN( WA_ATTACHMENT-DESCRIPTION ).
    LV_LENGTH_E  = STRLEN( LV_FILE_TYPE ) + 1.
    LV_LENGTH    = LV_LENGTH_F - LV_LENGTH_E.
    LV_FILE_NAME = WA_ATTACHMENT-DESCRIPTION(LV_LENGTH).

*   Original filename
    CONCATENATE '&SO_FILENAME='
                 WA_ATTACHMENT-DESCRIPTION
                INTO WA_HEADER-LINE.

    APPEND WA_HEADER TO IT_HEADER.

*   Decode Base64
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
      EXPORTING
        INPUT  = LV_DATA
      IMPORTING
        OUTPUT = LV_DATAX
      EXCEPTIONS
        FAILED = 1
        OTHERS = 2.

*   Document Information
    LV_DOC_DATA-OBJ_NAME   = LV_FILE_NAME.
    LV_DOC_DATA-OBJ_DESCR  = LV_FILE_NAME.
    LV_DOC_DATA-OBJ_LANGU  = SY-LANGU.
    LV_DOC_DATA-DOC_SIZE   = XSTRLEN( LV_DATAX ).

*   Convert to table
    CALL METHOD CL_DOCUMENT_BCS=>XSTRING_TO_SOLIX
      EXPORTING
        IP_XSTRING = LV_DATAX
      RECEIVING
        RT_SOLIX   = IT_SOLIX.

*   Insert Document
    CALL FUNCTION 'SO_DOCUMENT_INSERT_API1'
      EXPORTING
        FOLDER_ID                  = LV_OBJECT_ID
        DOCUMENT_DATA              = LV_DOC_DATA
        DOCUMENT_TYPE              = LV_DOC_TYPE
      IMPORTING
        DOCUMENT_INFO              = LV_DOC_INFO
      TABLES
        OBJECT_HEADER              = IT_HEADER
        CONTENTS_HEX               = IT_SOLIX
      EXCEPTIONS
        FOLDER_NOT_EXIST           = 1
        DOCUMENT_TYPE_NOT_EXIST    = 2
        OPERATION_NO_AUTHORIZATION = 3
        PARAMETER_ERROR            = 4
        X_ERROR                    = 5
        ENQUEUE_ERROR              = 6
        OTHERS                     = 7.

*    Relation Keys
    LV_ROLEA-OBJTYPE = WA_ATTACHMENT-TYPEID.
    LV_ROLEA-OBJKEY  = WA_ATTACHMENT-INSTID.

    LV_ROLEB-OBJTYPE = 'MESSAGE'.

    CONCATENATE LV_FOLDER_ID
                LV_DOC_INFO-OBJECT_ID
                INTO LV_ROLEB-OBJKEY RESPECTING BLANKS.

*   Create Relation
    CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
      EXPORTING
        OBJ_ROLEA      = LV_ROLEA
        OBJ_ROLEB      = LV_ROLEB
        RELATIONTYPE   = 'ATTA'
      EXCEPTIONS
        NO_MODEL       = 1
        INTERNAL_ERROR = 2
        UNKNOWN        = 3
        OTHERS         = 4.

  ENDLOOP.


* Delete
  LOOP AT IT_ATTACHMENT INTO WA_ATTACHMENT WHERE DELETE IS NOT INITIAL.

    CALL FUNCTION 'SO_DOCUMENT_DELETE_API1'
      EXPORTING
        DOCUMENT_ID                = WA_ATTACHMENT-INSTID_B
      EXCEPTIONS
        DOCUMENT_NOT_EXIST         = 1
        OPERATION_NO_AUTHORIZATION = 2
        PARAMETER_ERROR            = 3
        X_ERROR                    = 4
        ENQUEUE_ERROR              = 5
        OTHERS                     = 6.

*    Relation Keys
    LV_ROLEA-OBJTYPE = WA_ATTACHMENT-TYPEID.
    LV_ROLEA-OBJKEY  = WA_ATTACHMENT-INSTID.

    LV_ROLEB-OBJTYPE = 'MESSAGE'.
    LV_ROLEB-OBJKEY  = WA_ATTACHMENT-INSTID_B.

*   Create Relation
    CALL FUNCTION 'BINARY_RELATION_DELETE_COMMIT'
      EXPORTING
        OBJ_ROLEA      = LV_ROLEA
        OBJ_ROLEB      = LV_ROLEB
        RELATIONTYPE   = 'ATTA'
      EXCEPTIONS
        NO_MODEL       = 1
        INTERNAL_ERROR = 2
        UNKNOWN        = 3
        OTHERS         = 4.

  ENDLOOP.


* Clear
  CLEAR IT_ATTACH_NEW.
  CLEAR IT_ATTACHMENT.

* Get New
  CONCATENATE WA_ATTACHMENT-TYPEID
              '|'
              WA_ATTACHMENT-INSTID
              INTO LV_AJAX_VALUE.

  CALL METHOD GET_ATTACHMENT_LIST( LV_AJAX_VALUE ).


ENDMETHOD.
ENDCLASS.
