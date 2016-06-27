import sys; import os
sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('.'))

from flask import Flask, render_template, request, redirect
import subprocess
from Utils import  subprocess_helpers
from Utils.DataSource import *

app = Flask(__name__)
dataSource = DataSource()


def launch_preprocessors():
    process = subprocess.Popen(
        subprocess_helpers.python_path + " Daemons/QueryProcessorDaemon.py && " + subprocess_helpers.python_path + " Daemons/ArticleProcessorDaemon.py",
        executable=subprocess_helpers.executable, shell=True, universal_newlines=True)


@app.route("/", methods=["GET"])
def queries():
    # Get lists of query from database with counts of associated articles
    all_queries = dataSource.queries_route()
    queries_formatted = [{"id": q[0], "subject": q[1], "verb": q[2], "direct_obj": q[3], "indirect_obj": q[4],
                          "loc": q[5], "article_count": q[6]} for q in all_queries]

    return render_template("queries.html", queries=queries_formatted)


@app.route("/query", methods=["POST"])
def new_query():
    # TODO: server side validation
    subject = request.form["subject"]
    verb = request.form["verb"]
    direct_obj = request.form["direct-object"]
    indirect_obj = request.form["indirect-object"]
    loc = request.form["location"]
    email = request.form["user-email"]
    phone = request.form["user-phone"]
    # Put into database
    dataSource.new_query(email, phone, subject, verb, direct_obj, indirect_obj, loc)

    return redirect("/")


@app.route("/query/<query_id>", methods=["GET"])
def query(query_id):
    # find query by id
    # if we don't find a query with that id, 404

    articles, db_query = dataSource.query_route(query_id)

    if db_query is not None:
        articles_formatted = [{"title": a[0], "source": a[1], "url": a[2]} for a in articles]
        query_formatted = {"id": db_query[0], "subject": db_query[1], "verb": db_query[2],
                           "direct_obj": db_query[3], "indirect_obj": db_query[4], "loc": db_query[5]}
        return render_template("query.html", query=query_formatted, articles=articles_formatted)
    return render_template("404.html"), 404

@app.route("/articles", methods=["GET"])
def articles():
    articles = dataSource.articles_route()
    articles_formatted = [{"title": a[0], "source": a[1], "url": a[2]} for a in articles]
    return render_template("articles.html", articles=articles_formatted)


@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404


if __name__ == "__main__":
    app.run(debug=True)
