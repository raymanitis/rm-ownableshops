if not Config then Config = {} end

-- Discord Webhook Configuration
Config.Webhooks = {
    shop_purchase = {
        url = 'YOUR_WEBHOOK_URL',
        color = 65280, -- Green
        title = 'Shop Purchase'
    },
    shop_sale = {
        url = 'YOUR_WEBHOOK_URL',
        color = 16711680, -- Red
        title = 'Shop Sale'
    },
    item_transaction = {
        url = 'YOUR_WEBHOOK_URL',
        color = 255, -- Blue
        title = 'Shop Item Transaction'
    },
    employee_management = {
        url = 'YOUR_WEBHOOK_URL',
        color = 16776960, -- Yellow
        title = 'Employee Management'
    }
}