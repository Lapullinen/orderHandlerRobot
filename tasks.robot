*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    1s

*** Keywords ***
Get Url For Orders
    Add heading    Input URL for "orders.csv"-file
    Add text input    input    label=Enter URL
    ${response}=    Run dialog
    [Return]    ${response.input}

*** Keywords ***
Download Orders
    [Arguments]    ${url}
    Download    ${url}    overwrite=True

*** Keywords ***
Open RobotSpareBin Website
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[Website_Url]

*** Keywords ***
Wait And Close PopUp
    Wait Until Page Contains Element    class:btn.btn-dark
    Click Button    class:btn.btn-dark

*** Keywords ***
Fill Order Form
    [Arguments]    ${order_row}
    Select From List By Value    id:head        ${order_row}[Head]
    Click Element If Visible    id:id-body-${order_row}[Body]
    Input Text    class:form-control    ${order_row}[Legs]
    Input Text    id:address    ${order_row}[Address]

*** Keywords ***
Preview Order
    Click Button    id:preview
    Wait Until Page Contains Element    id:robot-preview-image

*** Keywords ***
Send Order
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Order

*** Keywords ***
Click Order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

*** Keywords ***
Save PO Receipt As PDF
    [Arguments]    ${PO_PDF}
    ${PO_RECEIPT}=   Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${PO_RECEIPT}    ${CURDIR}${/}output${/}receipts${/}Robot Order ${PO_PDF}.pdf
    [Return]    ${PO_PDF}

*** Keywords ***
Take A Pic Of The Robot
    [Arguments]    ${ROBOT_PIC}
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}robot pics${/}Robot Pic ${ROBOT_PIC}.png
    [Return]    ${ROBOT_PIC}

*** Keywords ***
Append Robot Pic to PO Receipt
    [Arguments]    ${ROBOT_PIC}    ${PO_PDF}
    ${files}=    Create List
    ...    ${CURDIR}${/}output${/}robot pics${/}Robot Pic ${ROBOT_PIC}.png
    Add Files To Pdf    ${files}    ${CURDIR}${/}output${/}receipts${/}Robot Order ${PO_PDF}.pdf    append:True

*** Keywords ***
Order Another Robot
    Wait Until Page Contains Element    id:order-another
    Click Button    id:order-another

*** Keywords ***
Archive Receipts
    Archive Folder With Zip  ${CURDIR}${/}output${/}receipts  ${CURDIR}${/}output${/}Robot Order Receipts.zip

*** Keywords ***
Close The Browser
    Close Browser

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Open RobotSpareBin Website
    ${url}=    Get Url For Orders
    Download Orders    ${url}
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order_row}    IN    @{orders}
        Wait And Close PopUp
        Fill Order Form    ${order_row}
        Preview Order
        Send Order
        ${PO_PDF}=    Save PO Receipt As PDF    ${order_row}[Order number]
        ${ROBOT_PIC}=    Take A Pic Of The Robot    ${order_row}[Order number]
        Append Robot Pic to PO Receipt    ${ROBOT_PIC}    ${PO_PDF}
        Order Another Robot
    END
    Archive Receipts
    [Teardown]    Close The Browser
