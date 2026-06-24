
dom_style = DOM.style("""
body {
  margin: 0;
  padding: 0;
}

h2, p {
  margin: 10px;
}


ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
  background-color: #333333;
  display: flex;
}

ul li a {
  display: block;
  color: white;
  padding: 14px 16px;
  text-decoration: none;
}

ul li a:hover:not(.active) {
  background-color: #111111;
}

ul li a.active {
  background-color: #04AA6D;
}
""")


column_style = DOM.style("""
.column {
  flex: 33.33%;
  padding: 5px;
}
""")