
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

table_style = DOM.style("""
  font-family: 'Segoe UI', Arial, sans-serif;
  padding: 30px;
  max-width: 800px;

  h2 {
      color: #2c3e50;
      margin-bottom: 20px;
  }

  table {
      width: 100%;
      border-collapse: collapse;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      border-radius: 8px;
      overflow: hidden;
  }

  th {
      background-color: #4A90E2;
      color: white;
      text-align: left;
      padding: 12px 15px;
      font-weight: 600;
  }

  td {
      padding: 12px 15px;
      border-bottom: 1px solid #e0e0e0;
  }

  tr:hover {
      background-color: #f8f9fa;
  }
  """)