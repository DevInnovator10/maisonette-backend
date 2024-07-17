# Versioned Database Views for Rails

Date: 2022-06-24

## Status

**DRAFT**

Data increases very every second. This fundamentally increases the query scope across the database tables, joins and relationships, which presents software projects with larger data demands, in effect regresses the performance.

To ensure these performance regressions are improved, a merging of tables to reduce the relationship scope helps level the query scope for data with database views.

## Context

The back office application needs a database views solution to help improve the time it tables the query to traverse the data scope.

Database views are powerful SQL constructs that appear to be overlooked by Rails gem developers because, at the moment, views lack out-of-the-box support from Rails itself.

Many of the more complex ActiveRecord scopes, relationships, and query objects we’ve come across could more clearly and composably be expressed as database views, and yet they seldom are.

The fundamental aim is to improve the time query it takes to return results from a database and use Scenic to manage the versioning of the views.

### Why?

Versioned database views (with scenic) are mostly used to achieve the following:

- Manage the creation, updates, and deletion of database views.

- Views (query) contain joins between multiple tables, producing a single result set, thus reducing the complexity.

- Views can contain only a subset of the data rather than the entire columns from the tables.

- Can use views to pre-aggregate data for analytic workloads, using aggregate functions, such as SUM, AVG, COUNT, etc.

- Views can be used to control the access to underlying data: for example, can create a view that contains an order for the US only, and then grant access to that view to relevant users. That way we are not exposing all the data from the table, restricting access to a table, while granting access to a view only.

- Views don’t consume space in your database (except some trivial amount of memory for storing query definition) — views don’t store physical data!

**Requirements:**

* Versioning the database views:
  * Scenic gem.
  * Rails gem.
  * Connection details to the database.

## Considerations

Scenic adds first-class support for database views to ActiveRecord migrations.

Scenic goes beyond basic create_view and drop_view support to offer a view versioning system that makes maintaining views as they change as simple and robust as managing tables via migrations.

It also ships with extensive support for materialized views.

With Scenic added to our Gemfile and installed, we have access to some handy generators that are going to help us create a view to encapsulating this domain object.

**Pros:**

* Ruby-based tool which is the main programming language for the back office application.
* It fits into the `rails DB: migrate` flow.
* Scenic is hackable allowing any Rails command or external process.
* It is extendable.

**Cons:**

* Scenic isn't part of the rails DB migration convention.
* Requires updates when table columns changes
* When a table is dropped, the associated view becomes irrelevant.
* Since views are created when a query requesting data from view is triggered, it's a bit slow.
* When views are created for large tables, they occupy more memory.


## Decision

The decision was to go with:

-  Scenic as it is the most compatible with the project and team. Being that the tool is tied into the Rails conventions and is open source.
- Though database optimization techniques are widely used, going with database views presents a better option for tackling query performance regression.


## Consequences
TBD

