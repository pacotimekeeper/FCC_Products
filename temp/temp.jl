
DOM.div(
            style = DOM.style("""
            * {
                box-sizing: border-box;
            }
            """),
            DOM.div(
                style = DOM.style("""
                .row {
                    display: flex;
                }
                """),
                DOM.div(
                    style = column_style, 
                    DOM.a(href = "https://www.baxter.com/",
                        DOM.img(src="https://cdn.worldvectorlogo.com/logos/baxter.svg"; style = "width:100%")
                    )
                ),
                DOM.div(
                    style = column_style, 
                    DOM.a(href = "https://www.unitedorthopedic.com/",
                        DOM.img(src="https://www.unitedorthopedic.com/wp-content/uploads/2025/01/United-logo-new.svg"; style = "width:100%")
                    )
                ),
                DOM.div(
                    style = column_style, 
                    DOM.a(href = "https://www.smith-nephew.com/en",
                        DOM.img(src="https://mc-4895e938-de31-484c-aa80-830364-cdn-endpoint.azureedge.net/-/media/project/smithandnephew/sitesettings/logo.svg?rev=23cce43476814f859aaff33ced056dc9"; style = "width:100%")
                    )
                )
            ),
        )