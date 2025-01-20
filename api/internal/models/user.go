package models

import (
	"time"

	"github.com/asaskevich/govalidator"
)

// User data structure
type User struct {
	UserUpdate
	Username string    `json:"username" valid:"type(string),required"`
	Created  time.Time `json:"created,omitempty"`
}

// Valid validates the User model
func (u User) Valid() error {
	_, err := govalidator.ValidateStruct(u)

	return err
}

// UserUpdate data structure
type UserUpdate struct {
	Fname   string    `json:"fname,omitempty" valid:"type(string),optional"`
	Lname   string    `json:"lname,omitempty" valid:"type(string),optional"`
	Age     int       `json:"age,omitempty" valid:"int,optional"`
	Updated time.Time `json:"updated,omitempty"`
}
