#!/bin/bash

# Set DATABASE_URL explicitly to ensure it points to the correct location
export DATABASE_URL="${DATABASE_URL:-sqlite:////app/data/bookkeep.db}"

if [[ "$DATABASE_URL" == sqlite:* ]]; then
    # Ensure data directory exists (where SQLite DB will be created)
        mkdir -p /app/data
            chmod 755 /app/data
            fi

            # Set PYTHONPATH - Alembic needs to import app.* modules
            export PYTHONPATH="/app/backend:$PYTHONPATH"

            # Bootstrap base schema before running incremental Alembic migrations.
            # create_all is idempotent: it creates missing tables but never drops existing ones.
            # This ensures the 'books' (and other) tables exist so that migrations 001+ can
            # safely run op.add_column() without hitting "no such table" errors on a fresh install.
            echo "Bootstrapping base schema via SQLAlchemy create_all..."
            cd /app/backend
            python -c "
            import sys, os
            sys.path.insert(0, '/app/backend')
            from app.database import engine, Base
            import app.models
            Base.metadata.create_all(bind=engine)
            print('Base schema ready.')
            "
            if [ $? -ne 0 ]; then
                echo "ERROR: Base schema bootstrap failed."
                    exit 1
                    fi

                    echo "Running database migrations..."
                    echo "DATABASE_URL: $DATABASE_URL"

                    cd /app/backend

                    # Check current Alembic tracking state
                    echo "Checking Alembic version..."
                    ALEMBIC_CURRENT=$(python -m alembic -c alembic.ini current 2>&1)
                    echo "Alembic current: $ALEMBIC_CURRENT"

                    # If there is no alembic_version table the command prints nothing or errors.
                    # This happens when the DB was bootstrapped via SQLAlchemy create_all without
                    # Alembic ever having run (legacy deployments). We detect this and stamp the
                    # database at the correct revision so Alembic only runs the truly new migrations.
                    if ! echo "$ALEMBIC_CURRENT" | grep -q "(head)\|Rev:"; then
                        echo "No Alembic version found. Checking whether the database already has tables..."

                            TABLES_EXIST=$(python -c "
                            import sys, os
                            sys.path.insert(0, '/app/backend')
                            from sqlalchemy import inspect, create_engine
                            engine = create_engine(os.environ['DATABASE_URL'])
                            try:
                                print('yes' if inspect(engine).has_table('users') else 'no')
