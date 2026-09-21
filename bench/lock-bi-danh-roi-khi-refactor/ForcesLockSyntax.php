<?php

namespace Tests\Feature;

use Illuminate\Database\Connection;
use Illuminate\Database\Query\Builder;
use Illuminate\Database\Query\Grammars\SQLiteGrammar;
use ReflectionClass;

/**
 * SQLite parses nothing for `SELECT ... FOR UPDATE`: Laravel's SQLiteGrammar
 * inherits compileLock() and returns an empty string, so lockForUpdate() is a
 * silent no-op on the sqlite test driver.
 *
 * Consequence: a test that asserts "this read is locked" by observing behaviour
 * passes whether or not the lock is there. This trait makes the lock visible in
 * the compiled SQL so an assertion can actually fail.
 */
trait ForcesLockSyntax
{
    protected function makeLockVisible(): void
    {
        $connection = $this->app['db']->connection();

        $connection->setQueryGrammar(new MarksLockInCompiledSql($connection));
    }

    /** @return string[] compiled SQL of every query run inside $fn */
    protected function captureSql(callable $fn): array
    {
        $sql = [];

        $this->app['db']->listen(function ($query) use (&$sql) {
            $sql[] = $query->sql;
        });

        $fn();

        return $sql;
    }
}

/**
 * Emits a marker comment where the lock clause would go.
 *
 * Laravel <= 11 query grammars take no constructor arguments; Laravel 12 passes
 * the Connection. The optional argument plus the reflection check below keeps
 * one class working on both.
 */
class MarksLockInCompiledSql extends SQLiteGrammar
{
    public function __construct(?Connection $connection = null)
    {
        $parent = (new ReflectionClass(SQLiteGrammar::class))->getConstructor();

        if ($parent !== null && $parent->getNumberOfRequiredParameters() > 0) {
            parent::__construct($connection);
        }
    }

    protected function compileLock(Builder $query, $value): string
    {
        if ($value === false || $value === null) {
            return '';
        }

        if (is_string($value)) {
            return ' /* ' . $value . ' */';
        }

        return $value ? ' /* for update */' : ' /* lock in share mode */';
    }
}
