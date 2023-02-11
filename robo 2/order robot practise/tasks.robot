*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             zipfile
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             Dialogs


*** Variables ***
${error_msg}
${orders}


*** Tasks ***
Order robots
    # Download the csv file
    Open the robot order website
    ${orders} =    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Log    ${row}[Body]
        Store the receipt as a PDF file    ${row}[Order number]
        Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]
        Go to order another robot
    END
    create a zip file for all the orders
    [Teardown]    close the browser


*** Keywords ***
Get orders
    # ${response} =    GET    https://robotsparebinindustries.com/orders.csv
    ${salesdata_url} =    Get Value From User
    ...    Please provide the url
    ...    default_value=https://robotsparebinindustries.com/orders.csv

    Download
    ...    ${salesdata_url}
    ...    target_file=orders.csv
    ...    overwrite=True
    ${table} =    Read table from CSV    orders.csv
    RETURN    ${table}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/
    # Log To Console    ${driver}
    Click Element If Visible    //a[@class="nav-link"]

Order robots from RobotSpareBin Industries Inc
    ${secret} =    Get Secret    locators
    Select From List By Value    head    2
    # Select Radio Button    body    1
    Click Element If Visible    ${secret}[body]    #//input[@name='body' and @value='1']
    Input Text When Element Is Visible    ${secret}[leg]    5
    #//input[@type='number' and contains(@placeholder, 'for the legs')]    5
    Input Text When Element Is Visible    address    abc
    Click Button When Visible    preview
    Click Button When Visible    order
    ${error_msg} =    Does Page Contain Element    //div[@class='alert alert-danger']
    IF    ${error_msg} == True    Click Button When Visible    order
    # WHILE    ${error_msg} == True
    #    Click Button When Visible    order
    # END

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element If Visible    //input[@name='body' and @value='${row}[Body]']
    Input Text When Element Is Visible
    ...    //input[@type='number' and contains(@placeholder, 'for the legs')]
    ...    ${row}[Legs]
    Input Text When Element Is Visible    address    ${row}[Address]

Preview the robot
    Click Button When Visible    preview

Submit the order
    Click Button When Visible    order
    ${error_msg} =    Is Element Visible    //div[@class='alert alert-danger']    missing_ok=True
    # IF    ${error_msg} == True
    #    Click Button When Visible    order
    #    # IF    ${error_msg} == True    Click Button When Visible    order
    # END
    WHILE    ${error_msg} == True
        Click Button When Visible    order
        ${error_msg} =    Is Element Visible    //div[@class='alert alert-danger']    missing_ok=True
    END

Go to order another robot
    Click Button When Visible    order-another

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:order-completion
    ${order_receipt} =    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}receipts${/}order_receipt_${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}preview_robot${/}order_${row}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${files} =    Create List
    ...    ${OUTPUT_DIR}${/}receipts${/}order_receipt_${row}.pdf
    ...    ${OUTPUT_DIR}${/}preview_robot${/}order_${row}.png

    Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}final_receipts${/}receipt_of_order_${row}.pdf

create a zip file for all the orders
    Archive Folder With Zip    ${OUTPUT_DIR}${/}final_receipts    ordered_robots.zip

close the browser
    Close Browser
