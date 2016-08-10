class CreateMinuteStations < ActiveRecord::Migration
  def change
    create_table :minute_stations, :id => false do |t|
      t.datetime :datetime, null: false
      t.string :site_number, null: false
      t.float :tempe
      t.float :max_tempe
      t.float :min_tempe
      t.float :rain

      t.timestamps null: false
    end
    add_index :minute_stations, [:datetime, :site_number], :unique => true

    # execute "ALTER TABLE auto_stations DROP PRIMARY KEY"
    execute "ALTER TABLE minute_stations add primary key(datetime, site_number)"

    # remove_index :minute_stations, [:id]

    # ADD PARTITION
    execute "
      ALTER TABLE minute_stations
      PARTITION BY RANGE (YEAR(datetime))
      (
        PARTITION p2014 VALUES LESS THAN (2014) ENGINE = InnoDB,
        PARTITION p2015 VALUES LESS THAN (2015) ENGINE = InnoDB,
        PARTITION p2016 VALUES LESS THAN (2016) ENGINE = InnoDB,
        PARTITION p2017 VALUES LESS THAN (2017) ENGINE = InnoDB,
        PARTITION p2018 VALUES LESS THAN (2018) ENGINE = InnoDB,
        PARTITION p2019 VALUES LESS THAN (2019) ENGINE = InnoDB,
        PARTITION p2020 VALUES LESS THAN (2020) ENGINE = InnoDB,
        PARTITION p2021 VALUES LESS THAN (2021) ENGINE = InnoDB,
        PARTITION p2022 VALUES LESS THAN (2022) ENGINE = InnoDB,
        PARTITION p2023 VALUES LESS THAN (2023) ENGINE = InnoDB,
        PARTITION p2024 VALUES LESS THAN (2024) ENGINE = InnoDB,
        PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
        PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
        PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
        PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB
      );
    "
  end
end
