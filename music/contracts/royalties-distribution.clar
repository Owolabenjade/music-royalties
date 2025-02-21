;; Decentralized Music Royalties Distribution Contract
;; Built with Clarity on the Stacks Blockchain

;; Project ID counter
(define-data-var next-project-id uint u1)

;; Main project data storage
(define-map projects 
    { id: uint }
    { creator: principal, 
      title: (string-ascii 256), 
      royalty-split: (list 3 uint),
      total-earned: uint,
      total-distributed: uint })

;; Store individual backer data
(define-map backers
    { project-id: uint, backer: principal }
    { amount: uint })

;; Store project backers by index
(define-map project-backers
    { project-id: uint, index: uint }
    { backer: principal })

;; Store backer count per project
(define-map backer-counts
    { project-id: uint }
    { count: uint })

;; Validate royalty split sum equals 100
(define-private (validate-royalty-split (split (list 3 uint)))
    (let ((total (+ (default-to u0 (element-at split u0)) 
                   (default-to u0 (element-at split u1)) 
                   (default-to u0 (element-at split u2)))))
        (is-eq total u100)
    )
)

;; Validate project ID exists
(define-private (validate-project-id (project-id uint))
    (is-some (map-get? projects { id: project-id }))
)

;; Validate string is not empty
(define-private (validate-non-empty-string (text (string-ascii 256)))
    (not (is-eq text ""))
)

;; Create a new music project
(define-public (create-project (title (string-ascii 256)) (royalty-split (list 3 uint)))
    (begin
        ;; Validate inputs
        (asserts! (validate-non-empty-string title) (err u400))
        (asserts! (validate-royalty-split royalty-split) (err u401))
        
        ;; Create project with validated inputs
        (let ((validated-title title)
              (validated-royalty-split royalty-split)
              (project-id (var-get next-project-id)))
            (map-set projects
                { id: project-id }
                { creator: tx-sender,
                  title: validated-title,
                  royalty-split: validated-royalty-split,
                  total-earned: u0,
                  total-distributed: u0 })
                  
            (map-set backer-counts
                { project-id: project-id }
                { count: u0 })
                
            (var-set next-project-id (+ project-id u1))
            
            (ok project-id)
        )
    )
)

;; Pledge funds to a project
(define-public (pledge (project-id uint) (amount uint))
    (begin
        ;; Validate inputs
        (asserts! (> amount u0) (err u402))
        (asserts! (validate-project-id project-id) (err u100))
        
        ;; Use validated project-id
        (let ((validated-project-id project-id)
              (validated-amount amount)
              (project-data (unwrap-panic (map-get? projects { id: project-id }))))
            
            ;; Check if backer exists
            (if (is-none (map-get? backers { project-id: validated-project-id, backer: tx-sender }))
                (let ((count-data (default-to { count: u0 } (map-get? backer-counts { project-id: validated-project-id }))))
                    (begin
                        ;; Add new backer
                        (map-set project-backers
                            { project-id: validated-project-id, index: (get count count-data) }
                            { backer: tx-sender })
                        
                        ;; Increment count
                        (map-set backer-counts
                            { project-id: validated-project-id }
                            { count: (+ (get count count-data) u1) })
                    )
                )
                true
            )
            
            ;; Update backer amount
            (map-set backers
                { project-id: validated-project-id, backer: tx-sender }
                { amount: validated-amount })
            
            ;; Update project total
            (map-set projects
                { id: validated-project-id }
                { creator: (get creator project-data),
                  title: (get title project-data),
                  royalty-split: (get royalty-split project-data),
                  total-earned: (+ (get total-earned project-data) validated-amount),
                  total-distributed: (get total-distributed project-data) })
            
            (ok true)
        )
    )
)

;; Distribute royalties
(define-public (distribute-royalties (project-id uint))
    (begin
        ;; Validate project-id
        (asserts! (validate-project-id project-id) (err u100))
        
        (let ((validated-project-id project-id)
              (project-data (unwrap-panic (map-get? projects { id: project-id }))))
            
            ;; Validate authorization
            (asserts! (is-eq tx-sender (get creator project-data)) (err u102))
            
            ;; Validate distribution not already done
            (asserts! (< (get total-distributed project-data) (get total-earned project-data)) (err u403))
            
            (let ((total-earned (get total-earned project-data))
                  (royalty-split (get royalty-split project-data)))
                
                ;; Pay creator
                (let ((creator-share (default-to u0 (element-at royalty-split u0)))
                      (creator-amount (/ (* total-earned creator-share) u100)))
                    (try! (stx-transfer? creator-amount tx-sender (get creator project-data)))
                )
                
                ;; Pay first backer if exists
                (if (is-some (map-get? project-backers { project-id: validated-project-id, index: u0 }))
                    (let ((backer-data (unwrap-panic (map-get? project-backers { project-id: validated-project-id, index: u0 })))
                          (first-share (default-to u0 (element-at royalty-split u1)))
                          (first-amount (/ (* total-earned first-share) u100)))
                        (try! (stx-transfer? first-amount tx-sender (get backer backer-data)))
                    )
                    true
                )
                
                ;; Pay second backer if exists
                (if (is-some (map-get? project-backers { project-id: validated-project-id, index: u1 }))
                    (let ((backer-data (unwrap-panic (map-get? project-backers { project-id: validated-project-id, index: u1 })))
                          (second-share (default-to u0 (element-at royalty-split u2)))
                          (second-amount (/ (* total-earned second-share) u100)))
                        (try! (stx-transfer? second-amount tx-sender (get backer backer-data)))
                    )
                    true
                )
                
                ;; Update distribution status
                (map-set projects
                    { id: validated-project-id }
                    { creator: (get creator project-data),
                      title: (get title project-data),
                      royalty-split: royalty-split,
                      total-earned: total-earned,
                      total-distributed: total-earned })
                
                (ok true)
            )
        )
    )
)